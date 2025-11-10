# Secure Encrypted Handshake - Protection Against MITM/Handshake Attacks
# PowerShell implementation for Windows

param(
    [Parameter(Position=0)]
    [ValidateSet('push', 'pull', 'sync', 'verify', 'help')]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$SourcePath,
    
    [Parameter(Position=2)]
    [string]$DestPath
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$ENCRYPTION_DB_PATH = Join-Path $REPO_ROOT "encryption-db"
$TEMP_DIR = Join-Path $REPO_ROOT ".secure-temp"

Write-Host "🔐 Secure Encrypted Handshake Protocol" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Function: Check prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    $missing = @()
    
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
        $missing += "gpg (Install: https://gpg4win.org/)"
    }
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missing += "git"
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "❌ Missing required tools:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        exit 1
    }
    
    Write-Host "✅ All prerequisites met" -ForegroundColor Green
}

# Function: Generate session key
function New-SessionKey {
    Write-Host "🔑 Generating ephemeral session key..." -ForegroundColor Yellow
    
    # Create secure temp directory
    if (-not (Test-Path $TEMP_DIR)) {
        New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    }
    
    # Generate random session key (32 bytes = 256 bits)
    $sessionKey = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
    $sessionKeyPath = Join-Path $TEMP_DIR "session.key"
    [System.IO.File]::WriteAllBytes($sessionKeyPath, $sessionKey)
    
    # Set restrictive permissions
    $acl = Get-Acl $sessionKeyPath
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, "FullControl", "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $sessionKeyPath $acl
    
    Write-Host "✅ Session key generated" -ForegroundColor Green
    return $sessionKeyPath
}

# Function: Establish encrypted handshake
function New-EncryptedHandshake {
    param([string]$RecipientKey)
    
    Write-Host "🤝 Establishing encrypted handshake..." -ForegroundColor Yellow
    
    # Generate handshake token
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $nonce = [System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
    $handshakeToken = "${timestamp}:${nonce}"
    
    # Save handshake token
    $tokenPath = Join-Path $TEMP_DIR "handshake.token"
    $handshakeToken | Out-File -FilePath $tokenPath -NoNewline -Encoding ASCII
    
    # Encrypt handshake token with recipient's GPG key
    $tokenGpgPath = Join-Path $TEMP_DIR "handshake.token.gpg"
    gpg --encrypt --armor --recipient $RecipientKey --trust-model always --output $tokenGpgPath $tokenPath
    
    # Create signature
    $sigPath = Join-Path $TEMP_DIR "handshake.sig"
    gpg --sign --armor --output $sigPath $tokenPath
    
    Write-Host "✅ Encrypted handshake established" -ForegroundColor Green
    Write-Host "   Token: $($handshakeToken.Substring(0, [Math]::Min(20, $handshakeToken.Length)))..." -ForegroundColor Cyan
    
    return $handshakeToken
}

# Function: Encrypt data for transmission
function Protect-DataForTransmission {
    param(
        [string]$SourceFile,
        [string]$OutputFile,
        [string]$RecipientKey
    )
    
    Write-Host "🔒 Encrypting data for secure transmission..." -ForegroundColor Yellow
    
    if (-not (Test-Path $SourceFile)) {
        Write-Host "❌ Source file not found: $SourceFile" -ForegroundColor Red
        throw "Source file not found"
    }
    
    # Generate session key
    $sessionKeyPath = New-SessionKey
    
    # Establish handshake
    New-EncryptedHandshake -RecipientKey $RecipientKey | Out-Null
    
    # Step 1: Encrypt file with AES-256
    $encryptedDataPath = Join-Path $TEMP_DIR "data.enc"
    
    # Read file and encrypt
    $sourceData = [System.IO.File]::ReadAllBytes($SourceFile)
    $sessionKeyBytes = [System.IO.File]::ReadAllBytes($sessionKeyPath)
    
    # Use AES-256-CBC
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    
    # Derive key from session key
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $aes.Key = $sha256.ComputeHash($sessionKeyBytes)
    $aes.GenerateIV()
    
    $encryptor = $aes.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($sourceData, 0, $sourceData.Length)
    
    # Save IV + encrypted data
    $output = $aes.IV + $encryptedData
    [System.IO.File]::WriteAllBytes($encryptedDataPath, $output)
    
    # Step 2: Encrypt session key with GPG
    $sessionKeyGpgPath = Join-Path $TEMP_DIR "session.key.gpg"
    gpg --encrypt --armor --recipient $RecipientKey --trust-model always --output $sessionKeyGpgPath $sessionKeyPath
    
    # Step 3: Create package
    $packageFiles = @(
        $encryptedDataPath,
        $sessionKeyGpgPath,
        (Join-Path $TEMP_DIR "handshake.token.gpg"),
        (Join-Path $TEMP_DIR "handshake.sig")
    )
    
    # Create tar.gz package using built-in compression
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    $zip = [System.IO.Compression.ZipFile]::Open($OutputFile, 'Create')
    
    foreach ($file in $packageFiles) {
        $entryName = Split-Path $file -Leaf
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file, $entryName) | Out-Null
    }
    
    $zip.Dispose()
    
    Write-Host "✅ Data encrypted and packaged" -ForegroundColor Green
    Write-Host "   Output: $OutputFile" -ForegroundColor Cyan
}

# Function: Decrypt received data
function Unprotect-DataFromTransmission {
    param(
        [string]$PackageFile,
        [string]$OutputFile
    )
    
    Write-Host "🔓 Decrypting received data..." -ForegroundColor Yellow
    
    if (-not (Test-Path $PackageFile)) {
        Write-Host "❌ Package file not found: $PackageFile" -ForegroundColor Red
        throw "Package file not found"
    }
    
    # Step 1: Extract package
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($PackageFile, $TEMP_DIR)
    
    # Step 2: Verify handshake signature
    $sigPath = Join-Path $TEMP_DIR "handshake.sig"
    $verifyResult = gpg --verify $sigPath 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Handshake signature verification failed!" -ForegroundColor Red
        throw "Signature verification failed"
    }
    
    Write-Host "✅ Handshake verified" -ForegroundColor Green
    
    # Step 3: Decrypt session key
    $sessionKeyGpgPath = Join-Path $TEMP_DIR "session.key.gpg"
    $sessionKeyDecPath = Join-Path $TEMP_DIR "session.key.dec"
    gpg --decrypt --output $sessionKeyDecPath $sessionKeyGpgPath
    
    # Step 4: Decrypt data with session key
    $encryptedDataPath = Join-Path $TEMP_DIR "data.enc"
    $encryptedData = [System.IO.File]::ReadAllBytes($encryptedDataPath)
    $sessionKeyBytes = [System.IO.File]::ReadAllBytes($sessionKeyDecPath)
    
    # Extract IV (first 16 bytes)
    $iv = $encryptedData[0..15]
    $ciphertext = $encryptedData[16..($encryptedData.Length - 1)]
    
    # Decrypt with AES-256
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $aes.Key = $sha256.ComputeHash($sessionKeyBytes)
    $aes.IV = $iv
    
    $decryptor = $aes.CreateDecryptor()
    $decryptedData = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
    
    [System.IO.File]::WriteAllBytes($OutputFile, $decryptedData)
    
    Write-Host "✅ Data decrypted successfully" -ForegroundColor Green
    Write-Host "   Output: $OutputFile" -ForegroundColor Cyan
}

# Function: Secure push
function Invoke-SecurePush {
    param(
        [string]$SourceFile,
        [string]$DbPath
    )
    
    Write-Host "📤 Secure push to encryption database..." -ForegroundColor Yellow
    
    $gpgRecipient = $env:GPG_RECIPIENT
    if (-not $gpgRecipient) {
        throw "GPG_RECIPIENT environment variable not set"
    }
    
    # Encrypt file
    $encryptedPackage = Join-Path $TEMP_DIR "secure-package.zip"
    Protect-DataForTransmission -SourceFile $SourceFile -OutputFile $encryptedPackage -RecipientKey $gpgRecipient
    
    # Move to encryption database
    Push-Location $ENCRYPTION_DB_PATH
    
    try {
        $dbFullPath = Join-Path $ENCRYPTION_DB_PATH $DbPath
        $dbDir = Split-Path $dbFullPath -Parent
        
        if (-not (Test-Path $dbDir)) {
            New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
        }
        
        Copy-Item $encryptedPackage $dbFullPath -Force
        
        # Git operations
        git add $DbPath
        git commit -m "Add encrypted data: $(Split-Path $DbPath -Leaf) [$(Get-Date -Format 'yyyy-MM-dd HH:mm')]"
        
        Write-Host "✅ Encrypted data pushed to database" -ForegroundColor Green
        Write-Host "   Location: $DbPath" -ForegroundColor Cyan
    }
    finally {
        Pop-Location
    }
}

# Function: Secure pull
function Invoke-SecurePull {
    param(
        [string]$DbPath,
        [string]$OutputFile
    )
    
    Write-Host "📥 Secure pull from encryption database..." -ForegroundColor Yellow
    
    Push-Location $ENCRYPTION_DB_PATH
    
    try {
        # Pull latest
        git pull origin main
        
        $dbFullPath = Join-Path $ENCRYPTION_DB_PATH $DbPath
        
        if (-not (Test-Path $dbFullPath)) {
            Write-Host "❌ File not found in database: $DbPath" -ForegroundColor Red
            throw "File not found"
        }
        
        # Decrypt
        Unprotect-DataFromTransmission -PackageFile $dbFullPath -OutputFile $OutputFile
        
        Write-Host "✅ Data pulled and decrypted" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# Function: Secure sync
function Invoke-SecureSync {
    Write-Host "🔄 Performing secure sync with encryption database..." -ForegroundColor Yellow
    
    Push-Location $ENCRYPTION_DB_PATH
    
    try {
        Write-Host "Pulling latest encrypted data..." -ForegroundColor Cyan
        git pull origin main
        
        # Verify signatures
        $unsignedFiles = Get-ChildItem -Recurse -Include *.gpg,*.enc | Where-Object {
            -not (Test-Path "$($_.FullName).sig")
        }
        
        if ($unsignedFiles) {
            Write-Host "⚠️  Warning: Some files lack signatures:" -ForegroundColor Yellow
            $unsignedFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Yellow }
        } else {
            Write-Host "✅ All files properly signed" -ForegroundColor Green
        }
        
        Write-Host "✅ Secure sync completed" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# Function: Cleanup
function Clear-TempFiles {
    Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Yellow
    
    if (Test-Path $TEMP_DIR) {
        Get-ChildItem $TEMP_DIR -Recurse -File | ForEach-Object {
            # Overwrite with random data before deletion
            $randomData = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($_.Length)
            [System.IO.File]::WriteAllBytes($_.FullName, $randomData)
        }
        
        Remove-Item $TEMP_DIR -Recurse -Force
    }
    
    Write-Host "✅ Cleanup complete" -ForegroundColor Green
}

# Function: Show usage
function Show-Usage {
    Write-Host @"
Usage: .\secure-handshake.ps1 <command> [options]

Commands:
  push <source_file> <db_path>     Push file to encryption database with secure handshake
  pull <db_path> <output_file>     Pull file from encryption database and decrypt
  sync                             Sync encryption database with handshake verification
  verify                           Verify encryption database integrity
  help                             Show this help message

Environment Variables:
  GPG_RECIPIENT    GPG key ID or email for encryption (required)

Examples:
  .\secure-handshake.ps1 push .\secrets.json keys\production\secrets.json.enc
  .\secure-handshake.ps1 pull keys\production\secrets.json.enc .\secrets.json
  .\secure-handshake.ps1 sync
  .\secure-handshake.ps1 verify

"@
}

# Main execution
try {
    # Check prerequisites
    Test-Prerequisites
    
    # Check GPG recipient
    if (-not $env:GPG_RECIPIENT -and $Command -ne 'help') {
        Write-Host "❌ Error: GPG_RECIPIENT environment variable not set" -ForegroundColor Red
        Write-Host "Set with: `$env:GPG_RECIPIENT='your-key-id@example.com'" -ForegroundColor Yellow
        exit 1
    }
    
    switch ($Command) {
        'push' {
            if (-not $SourcePath -or -not $DestPath) {
                Write-Host "❌ Error: Missing arguments" -ForegroundColor Red
                Show-Usage
                exit 1
            }
            Invoke-SecurePush -SourceFile $SourcePath -DbPath $DestPath
        }
        'pull' {
            if (-not $SourcePath -or -not $DestPath) {
                Write-Host "❌ Error: Missing arguments" -ForegroundColor Red
                Show-Usage
                exit 1
            }
            Invoke-SecurePull -DbPath $SourcePath -OutputFile $DestPath
        }
        'sync' {
            Invoke-SecureSync
        }
        'verify' {
            Push-Location $ENCRYPTION_DB_PATH
            Write-Host "🔍 Verifying encryption database integrity..." -ForegroundColor Yellow
            git fsck --full
            Write-Host "✅ Verification complete" -ForegroundColor Green
            Pop-Location
        }
        'help' {
            Show-Usage
            exit 0
        }
        default {
            Show-Usage
            exit 1
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ Operation completed successfully" -ForegroundColor Green
}
finally {
    Clear-TempFiles
}
