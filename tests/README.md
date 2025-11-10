# Testing Guide

## Quick Start

Run the full test suite:

```powershell
.\tests\test-encryption-framework.ps1
```

With verbose output:

```powershell
.\tests\test-encryption-framework.ps1 -Verbose
```

## What Gets Tested

1. **Prerequisites** - Git, GPG installed
2. **File Structure** - All required files present
3. **Security Rules** - .gitignore configured properly
4. **Script Syntax** - No syntax errors
5. **GPG Setup** - GPG operational and keys available
6. **Workflow Simulation** - File operations work
7. **CI/CD Config** - GitHub Actions properly configured

## Next Steps After Tests Pass

1. Configure GPG key: `$env:GPG_RECIPIENT="your-key@example.com"`
2. Initialize encryption DB: `.\scripts\encryption\init-encryption-db.ps1`
3. Test handshake: `.\scripts\encryption\secure-handshake.ps1 help`
