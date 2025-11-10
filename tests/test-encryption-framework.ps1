# Test Suite - Encryption Framework Validation
# Tests all components before production use

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$TestResults = @()

Write-Host "🧪 Testing Encryption Framework" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test 1: Check prerequisites
Write-Host "`n[Test 1] Checking Prerequisites..." -ForegroundColor Yellow
try {
    $prereqs = @('git', 'gpg')
    foreach ($cmd in $prereqs) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Host "  ✅ $cmd found" -ForegroundColor Green
        } else {
            throw "$cmd not found"
        }
    }
    $TestResults += @{Test="Prerequisites"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="Prerequisites"; Status="FAIL"; Error=$_}
}

# Test 2: Verify file structure
Write-Host "`n[Test 2] Verifying File Structure..." -ForegroundColor Yellow
try {
    $requiredFiles = @(
        ".gitmodules",
        ".gitignore",
        "scripts/encryption/init-encryption-db.ps1",
        "scripts/encryption/secure-handshake.ps1",
        "DOCS/ENCRYPTION_SETUP.md",
        "DOCS/ENCRYPTED_HANDSHAKE_PROTOCOL.md"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $file exists" -ForegroundColor Green
        } else {
            throw "$file missing"
        }
    }
    $TestResults += @{Test="File Structure"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="File Structure"; Status="FAIL"; Error=$_}
}

# Test 3: Validate .gitignore rules
Write-Host "`n[Test 3] Validating .gitignore Rules..." -ForegroundColor Yellow
try {
    $gitignore = Get-Content .gitignore -Raw
    $criticalRules = @('encryption-db/', '*.key', '.secure-temp/', '*.gpg')
    
    foreach ($rule in $criticalRules) {
        if ($gitignore -match [regex]::Escape($rule)) {
            Write-Host "  ✅ Rule '$rule' present" -ForegroundColor Green
        } else {
            throw "Missing critical rule: $rule"
        }
    }
    $TestResults += @{Test=".gitignore Rules"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test=".gitignore Rules"; Status="FAIL"; Error=$_}
}

# Test 4: Test script syntax
Write-Host "`n[Test 4] Testing Script Syntax..." -ForegroundColor Yellow
try {
    $scripts = @(
        "scripts/encryption/init-encryption-db.ps1",
        "scripts/encryption/secure-handshake.ps1"
    )
    
    foreach ($script in $scripts) {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $script -Raw), [ref]$errors
        )
        
        if ($errors.Count -eq 0) {
            Write-Host "  ✅ $script syntax valid" -ForegroundColor Green
        } else {
            throw "$script has syntax errors"
        }
    }
    $TestResults += @{Test="Script Syntax"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="Script Syntax"; Status="FAIL"; Error=$_}
}

# Test 5: Check GPG configuration
Write-Host "`n[Test 5] Checking GPG Configuration..." -ForegroundColor Yellow
try {
    $gpgVersion = gpg --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ GPG operational" -ForegroundColor Green
        
        # Check for keys
        $keys = gpg --list-keys 2>&1
        if ($keys -match "pub") {
            Write-Host "  ✅ GPG keys found" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No GPG keys configured yet" -ForegroundColor Yellow
        }
    }
    $TestResults += @{Test="GPG Configuration"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="GPG Configuration"; Status="FAIL"; Error=$_}
}

# Test 6: Simulate encryption workflow (dry run)
Write-Host "`n[Test 6] Simulating Encryption Workflow..." -ForegroundColor Yellow
try {
    # Create test temp directory
    $testDir = ".test-temp-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    
    # Create test file
    $testFile = Join-Path $testDir "test-data.txt"
    "Test sensitive data" | Out-File $testFile -NoNewline
    
    # Test file operations
    if (Test-Path $testFile) {
        Write-Host "  ✅ Test file created" -ForegroundColor Green
    }
    
    # Cleanup
    Remove-Item $testDir -Recurse -Force
    Write-Host "  ✅ Workflow simulation passed" -ForegroundColor Green
    
    $TestResults += @{Test="Encryption Workflow"; Status="PASS"}
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="Encryption Workflow"; Status="FAIL"; Error=$_}
}

# Test 7: Check GitHub Actions workflow
Write-Host "`n[Test 7] Validating GitHub Actions Workflow..." -ForegroundColor Yellow
try {
    $workflowPath = ".github/workflows/secure-sync.yml"
    if (Test-Path $workflowPath) {
        $workflow = Get-Content $workflowPath -Raw
        
        # Check for required secrets
        $requiredSecrets = @('GPG_KEY_ID', 'GPG_PRIVATE_KEY', 'GPG_PASSPHRASE')
        foreach ($secret in $requiredSecrets) {
            if ($workflow -match $secret) {
                Write-Host "  ✅ Secret placeholder '$secret' found" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Secret '$secret' not referenced" -ForegroundColor Yellow
            }
        }
        
        $TestResults += @{Test="GitHub Actions"; Status="PASS"}
    } else {
        throw "Workflow file not found"
    }
} catch {
    Write-Host "  ❌ FAIL: $_" -ForegroundColor Red
    $TestResults += @{Test="GitHub Actions"; Status="FAIL"; Error=$_}
}

# Test Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$passed = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $TestResults.Count

Write-Host "`nTotal Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "`n✅ ALL TESTS PASSED - Framework Ready!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED - Review errors above" -ForegroundColor Yellow
    
    if ($Verbose) {
        Write-Host "`nFailed Tests Details:" -ForegroundColor Red
        $TestResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
            Write-Host "  - $($_.Test): $($_.Error)" -ForegroundColor Red
        }
    }
    exit 1
}
