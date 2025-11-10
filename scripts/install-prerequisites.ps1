# Quick Installer - Run as Administrator
# This installs all required tools for the encryption framework

Write-Host "🚀 Installing Encryption Framework Prerequisites" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green

# Install Chocolatey if not present
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "✅ Chocolatey ready" -ForegroundColor Green

# Install required packages
Write-Host "`n📦 Installing Git..." -ForegroundColor Yellow
choco install git -y

Write-Host "`n📦 Installing GPG4Win..." -ForegroundColor Yellow
choco install gpg4win -y

# Refresh PATH
Write-Host "`n🔄 Refreshing environment..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verify installations
Write-Host "`n✅ Verifying installations..." -ForegroundColor Cyan

$git = Get-Command git -ErrorAction SilentlyContinue
$gpg = Get-Command gpg -ErrorAction SilentlyContinue

if ($git) {
    Write-Host "  ✅ Git: $(git --version)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Git not found" -ForegroundColor Red
}

if ($gpg) {
    Write-Host "  ✅ GPG: $(gpg --version | Select-Object -First 1)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  GPG not found - may need to restart terminal" -ForegroundColor Yellow
}

Write-Host "`n🎉 Installation complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Close and reopen PowerShell (or VSCode)" -ForegroundColor White
Write-Host "2. Run: gpg --full-generate-key" -ForegroundColor White
Write-Host "3. Navigate to repo and run: .\tests\test-encryption-framework.ps1" -ForegroundColor White

pause
