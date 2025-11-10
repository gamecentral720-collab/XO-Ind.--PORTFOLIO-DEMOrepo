# System Setup Guide - Encrypted Architecture

## Overview

This guide walks through setting up the encrypted handshake architecture on a new system. Follow these steps carefully to maintain security integrity.

## Prerequisites Installation

### Windows

```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install git -y
choco install gpg4win -y

# Verify installations
git --version
gpg --version
```

### Linux/Mac

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git gnupg openssl -y

# Mac
brew install git gnupg openssl
```

## GPG Key Generation

### Generate Your Keys

```powershell
# Generate new GPG key pair (4096-bit RSA)
gpg --full-generate-key

# When prompted:
# - Key type: (1) RSA and RSA
# - Key size: 4096
# - Expiration: 1y (rotate annually)
# - Real name: Your Name
# - Email: your-secure-email@example.com
# - Passphrase: Strong passphrase (20+ characters)
```

### Export Keys (Backup)

```powershell
# List your keys
gpg --list-keys

# Export public key
gpg --armor --export your-email@example.com > public-key.asc

# Export private key (KEEP SECURE!)
gpg --armor --export-secret-keys your-email@example.com > private-key.asc

# Store private-key.asc in secure offline storage
# NEVER commit to any repository
```

## Repository Setup

### 1. Clone Main Repository

```powershell
git clone https://github.com/gamecentral720-collab/XO-Ind.--PORTFOLIO-DEMOrepo.git
cd XO-Ind.--PORTFOLIO-DEMOrepo
```

### 2. Create Encryption Database Repository

```powershell
# Create new PRIVATE repository on GitHub
# Name: encryption-keys (or your chosen name)
# Visibility: PRIVATE
# Do NOT initialize with README

# Note the URL for next step
```

### 3. Initialize Encryption Database

```powershell
# Set your GPG key
$env:GPG_RECIPIENT = "your-email@example.com"

# Run initialization script
.\scripts\encryption\init-encryption-db.ps1

# When prompted, enter your encryption repo URL:
# git@github.com:your-org/encryption-keys.git
```

## Configuration

### Environment Variables

```powershell
# Add to your PowerShell profile
notepad $PROFILE

# Add this line:
$env:GPG_RECIPIENT = "your-email@example.com"

# Save and reload
. $PROFILE
```

### Git Configuration

```powershell
# Configure commit signing (optional but recommended)
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

## Verification

### Test Basic Encryption

```powershell
# Create test file
"Test data" | Out-File test.txt

# Encrypt
gpg --encrypt --recipient your-email@example.com test.txt

# Decrypt
gpg --decrypt test.txt.gpg

# Cleanup
Remove-Item test.txt, test.txt.gpg
```

### Test Framework

```powershell
# Run test suite (once in repo directory)
.\tests\test-encryption-framework.ps1 -Verbose
```

## Security Hardening

### 1. Restrict Permissions

```powershell
# Windows: Set folder permissions
icacls encryption-db /inheritance:r
icacls encryption-db /grant:r "$env:USERNAME:(OI)(CI)F"

# Remove other users
icacls encryption-db /remove "Users"
```

### 2. Enable GPG Agent

```powershell
# GPG agent caches passphrase (default 10 min)
# Adjust cache time in: %APPDATA%\gnupg\gpg-agent.conf

# Create config file:
notepad "$env:APPDATA\gnupg\gpg-agent.conf"

# Add:
default-cache-ttl 600
max-cache-ttl 7200
```

### 3. Secure Backup

```powershell
# Backup GPG keys to encrypted USB drive
# Store in physical safe or safety deposit box
# Never store unencrypted keys in cloud storage
```

## Team Onboarding

### Share Public Key

```powershell
# Export your public key
gpg --armor --export your-email@example.com > team-member.pub

# Team member imports:
gpg --import team-member.pub

# Trust the key:
gpg --edit-key your-email@example.com
# > trust
# > 5 (ultimate)
# > quit
```

### Grant Repository Access

```
1. Add team member to encryption-keys repository
2. Grant minimum required permissions
3. Provide this setup guide
4. Verify they can decrypt test file
```

## GitHub Secrets Configuration

### Required Secrets

```
Repository Settings → Secrets and Variables → Actions:

1. GPG_KEY_ID
   Value: Your GPG key ID (from gpg --list-keys)

2. GPG_PRIVATE_KEY
   Value: Contents of private-key.asc (armored format)

3. GPG_PASSPHRASE
   Value: Your GPG key passphrase

4. GH_PAT_WITH_SUBMODULE_ACCESS
   Value: GitHub Personal Access Token with repo access
```

## Usage Examples

### Push Encrypted Data

```powershell
.\scripts\encryption\secure-handshake.ps1 push `
    .\config\production.json `
    keys\production\config.json.enc
```

### Pull Encrypted Data

```powershell
.\scripts\encryption\secure-handshake.ps1 pull `
    keys\production\config.json.enc `
    .\config\production.json
```

### Sync Database

```powershell
.\scripts\encryption\secure-handshake.ps1 sync
```

## Troubleshooting

### GPG "No Secret Key"

```powershell
# Reimport private key
gpg --import private-key.asc

# Verify
gpg --list-secret-keys
```

### Permission Denied

```powershell
# Check file permissions
Get-Acl encryption-db

# Reset if needed
icacls encryption-db /reset
```

### Handshake Verification Failed

```powershell
# Check GPG trust
gpg --edit-key your-email@example.com
# > trust
# > 5
# > quit
```

## Security Checklist

- [ ] GPG keys generated (4096-bit)
- [ ] Private key backed up offline
- [ ] Environment variables configured
- [ ] Encryption repository is PRIVATE
- [ ] .gitignore rules verified
- [ ] Test suite passes
- [ ] Team members trained
- [ ] GitHub secrets configured
- [ ] Access audit completed

## Emergency Procedures

### Key Compromise

```powershell
# 1. Immediately revoke compromised key
gpg --gen-revoke your-email@example.com > revoke.asc
gpg --import revoke.asc
gpg --send-keys YOUR_KEY_ID

# 2. Generate new keys
# 3. Re-encrypt all data
# 4. Update all systems
# 5. Document in incident log
```

### Lost Access

```
1. Contact repository administrator
2. Verify identity through secure channel
3. Restore from backup keys
4. Update access logs
```

## Support

For issues or questions:
- Email: katdevops099@gmail.com
- Repository: Create issue with [SECURITY] tag
- Emergency: Follow incident runbook

---

**CONFIDENTIAL - INTERNAL USE ONLY**  
Last Updated: 2025-11-10  
Version: 1.0
