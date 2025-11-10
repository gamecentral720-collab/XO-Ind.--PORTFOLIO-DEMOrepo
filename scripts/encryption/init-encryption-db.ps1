# PowerShell script to initialize PGP Encryption Database Submodule
# This script safely initializes the encryption database without exposing sensitive data

$ErrorActionPreference = "Stop"

$ENCRYPTION_DB_PATH = "encryption-db"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)

Write-Host "🔐 Initializing PGP Encryption Database Framework" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: git is not installed" -ForegroundColor Red
    exit 1
}

Set-Location $REPO_ROOT

# Check if .gitmodules exists
if (-not (Test-Path .gitmodules)) {
    Write-Host "❌ Error: .gitmodules not found. Run this script from repository root." -ForegroundColor Red
    exit 1
}

# Check if submodule is already initialized
if (Test-Path "$ENCRYPTION_DB_PATH\.git") {
    Write-Host "⚠️  Encryption database submodule already initialized" -ForegroundColor Yellow
    $response = Read-Host "Do you want to update it? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "📥 Updating encryption database submodule..." -ForegroundColor Green
        git submodule update --remote $ENCRYPTION_DB_PATH
    }
} else {
    Write-Host "📥 Initializing encryption database submodule..." -ForegroundColor Green
    
    # Prompt for the PGP repository URL
    Write-Host ""
    Write-Host "Enter your PGP encryption repository URL:"
    Write-Host "Example: git@github.com:your-org/encryption-keys.git"
    $PGP_REPO_URL = Read-Host "URL"
    
    if ([string]::IsNullOrWhiteSpace($PGP_REPO_URL)) {
        Write-Host "❌ Error: Repository URL cannot be empty" -ForegroundColor Red
        exit 1
    }
    
    # Update .gitmodules with the actual URL
    git config -f .gitmodules submodule.encryption-db.url $PGP_REPO_URL
    
    # Initialize the submodule
    git submodule init
    git submodule update --depth 1
    
    Write-Host "✅ Encryption database submodule initialized" -ForegroundColor Green
}

# Create README if it doesn't exist in submodule
if (Test-Path $ENCRYPTION_DB_PATH) {
    if (-not (Test-Path "$ENCRYPTION_DB_PATH\README.md")) {
        Write-Host "📝 Creating README.md in encryption database..." -ForegroundColor Green
        
        $readmeContent = @"
# PGP Encryption Database

This directory contains encrypted keys and sensitive cryptographic material.

## Security Guidelines

1. **Never commit unencrypted keys** to this repository
2. **Always use GPG/PGP encryption** for all sensitive files
3. **Rotate keys regularly** according to your security policy
4. **Limit access** to this repository to authorized personnel only
5. **Audit access logs** regularly

## Structure

- ``keys/`` - Encrypted PGP keys
- ``certs/`` - Encrypted certificates
- ``config/`` - Encrypted configuration files

## Usage

All files should be encrypted before committing:
``````powershell
gpg --encrypt --recipient your-key-id sensitive-file
``````

## Emergency Key Rotation

In case of compromise, follow the incident response procedure in:
``docs/incident-runbook.md``
"@
        
        Set-Content -Path "$ENCRYPTION_DB_PATH\README.md" -Value $readmeContent
        Write-Host "✅ README.md created" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "✅ Encryption database framework initialized" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Add your encrypted PGP keys to: $ENCRYPTION_DB_PATH\"
Write-Host "2. Commit and push this configuration"
Write-Host "3. Ensure team members have GPG configured"
Write-Host "4. Review security measures in DOCS\SECURITY_MEASURES_Version2.md"
Write-Host ""
Write-Host "⚠️  Security Reminder:" -ForegroundColor Yellow
Write-Host "   - The encryption-db/ directory is in .gitignore"
Write-Host "   - Only encrypted files should be committed to the submodule"
Write-Host "   - Never share private keys through this repository"
Write-Host ""
