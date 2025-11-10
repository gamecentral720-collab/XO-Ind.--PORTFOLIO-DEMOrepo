# PGP Encryption Database Setup Guide

## Overview

This repository uses a **separate Git submodule** for storing encrypted keys and sensitive cryptographic material. This architectural separation provides defense-in-depth against attacks by isolating the encryption database from the main codebase.

## Architecture

```
XO-Ind.--PORTFOLIO-DEMOrepo/          (Main Repository)
│
├── encryption-db/                     (Git Submodule - Separate Repo)
│   ├── keys/                          (Encrypted PGP keys)
│   ├── certs/                         (Encrypted certificates)
│   └── config/                        (Encrypted config files)
│
├── scripts/encryption/
│   ├── init-encryption-db.sh          (Linux/Mac initialization)
│   └── init-encryption-db.ps1         (Windows initialization)
│
└── .gitmodules                        (Submodule configuration)
```

## Security Benefits

1. **Separation of Concerns**: Encryption keys are in a separate repository with different access controls
2. **Access Control**: Can restrict who has access to the encryption-db repository
3. **Audit Trail**: Separate commit history for encryption material
4. **Blast Radius Limitation**: Compromise of main repo doesn't expose encryption keys
5. **Selective Cloning**: Users can clone main repo without encryption keys

## Initial Setup

### Prerequisites

- Git 2.13+ (for submodule support)
- GPG/PGP tools installed (`gpg` command available)
- Access to your PGP encryption repository

### Step 1: Create Your Encryption Repository

First, create a **private** repository for your encryption database:

```bash
# On GitHub, GitLab, or your Git hosting platform
# Create a new PRIVATE repository named: encryption-keys (or similar)
```

### Step 2: Initialize the Framework

**On Windows (PowerShell):**
```powershell
.\scripts\encryption\init-encryption-db.ps1
```

**On Linux/Mac (Bash):**
```bash
chmod +x scripts/encryption/init-encryption-db.sh
./scripts/encryption/init-encryption-db.sh
```

When prompted, enter your encryption repository URL:
```
git@github.com:your-org/encryption-keys.git
# or
https://github.com/your-org/encryption-keys.git
```

### Step 3: Add Encrypted Keys

```bash
cd encryption-db/

# Create directory structure
mkdir -p keys certs config

# Encrypt and add your keys (example)
gpg --encrypt --recipient YOUR_KEY_ID --output keys/prod.key.gpg keys/prod.key

# Add and commit (only encrypted files!)
git add keys/prod.key.gpg
git commit -m "Add encrypted production key"
git push origin main
```

### Step 4: Update Main Repository

```bash
cd ..  # Back to main repo
git add .gitmodules encryption-db
git commit -m "Add encryption database submodule"
git push
```

## Daily Usage

### Cloning the Repository (New Team Member)

```bash
# Clone main repository
git clone <main-repo-url>
cd XO-Ind.--PORTFOLIO-DEMOrepo

# Initialize and fetch encryption submodule
git submodule init
git submodule update

# You may need authentication for the encryption-db submodule
```

### Updating Encryption Database

```bash
# Pull latest encryption keys
cd encryption-db
git pull origin main
cd ..

# Or from main repo
git submodule update --remote encryption-db
```

### Adding New Encrypted Files

```bash
cd encryption-db

# Always encrypt before adding
gpg --encrypt --recipient YOUR_KEY_ID sensitive-file

# Add only the encrypted version
git add sensitive-file.gpg
git commit -m "Add encrypted sensitive file"
git push

# Update main repo to reference new commit
cd ..
git add encryption-db
git commit -m "Update encryption database reference"
git push
```

### Decrypting Files (Local Use Only)

```bash
cd encryption-db
gpg --decrypt keys/prod.key.gpg > /tmp/prod.key

# Use the decrypted key (never commit!)
# Clean up immediately after use
shred -u /tmp/prod.key  # Linux
# or
Remove-Item /tmp/prod.key -Force  # Windows
```

## Security Best Practices

### ✅ DO

1. **Always encrypt** before committing to encryption-db
2. **Use strong GPG keys** (4096-bit RSA minimum)
3. **Rotate keys regularly** (quarterly or per policy)
4. **Limit access** to encryption-db repository
5. **Audit access logs** regularly
6. **Use hardware keys** (YubiKey) for GPG operations when possible
7. **Keep backups** of your GPG private keys in secure offline storage

### ❌ DON'T

1. **Never commit unencrypted keys** to any repository
2. **Never share GPG private keys** through the repository
3. **Don't store decrypted files** in the working directory
4. **Don't use weak or default keys**
5. **Don't grant unnecessary access** to encryption-db
6. **Don't skip key rotation**

## Emergency Procedures

### Compromised Key

1. **Immediately revoke** the compromised key
2. **Rotate all keys** encrypted with the compromised key
3. **Notify security team** and follow incident runbook
4. **Audit access logs** to determine exposure
5. **Document in postmortem** (see `docs/postmortem-template.md`)

### Lost Access to Encryption Repository

1. Contact repository administrator
2. Verify identity through secure channel
3. Re-grant access with new credentials
4. Re-encrypt keys if credentials were potentially compromised

## CI/CD Integration

### GitHub Actions (Example)

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout with submodules
        uses: actions/checkout@v4
        with:
          submodules: true
          token: ${{ secrets.GH_PAT_WITH_SUBMODULE_ACCESS }}
      
      - name: Import GPG key
        run: |
          echo "${{ secrets.GPG_PRIVATE_KEY }}" | gpg --import
      
      - name: Decrypt secrets
        run: |
          cd encryption-db
          gpg --decrypt --output ../config/prod.env config/prod.env.gpg
      
      - name: Deploy
        run: ./scripts/deploy/deploy-staging.sh
```

**Note**: Store GPG private key in GitHub Secrets with appropriate protection rules.

## Access Control Matrix

| Role | Main Repo | Encryption DB | GPG Private Key |
|------|-----------|---------------|-----------------|
| Developer | Read/Write | No Access | No |
| DevOps | Read/Write | Read | Yes (for deployment) |
| Security Lead | Read/Write | Read/Write | Yes |
| Admin | Read/Write | Read/Write | Yes |

## Compliance & Auditing

### Regular Audits

- **Monthly**: Review encryption-db access logs
- **Quarterly**: Rotate keys and review permissions
- **Annually**: Full security audit of encryption practices

### Documentation Requirements

- Maintain key inventory in encryption-db
- Document key rotation dates
- Track who has access to GPG keys
- Record all key compromise incidents

## Troubleshooting

### Submodule Not Initializing

```bash
# Re-initialize submodule
git submodule deinit -f encryption-db
git submodule init
git submodule update --force
```

### Access Denied to Encryption Repository

```bash
# Check your SSH keys
ssh -T git@github.com

# Or use HTTPS with PAT
git config submodule.encryption-db.url https://YOUR_PAT@github.com/org/repo.git
```

### GPG Decryption Fails

```bash
# List available keys
gpg --list-keys

# Import missing key
gpg --import /path/to/private-key.asc
```

## References

- [GPG Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)
- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- Main repo security measures: `DOCS/SECURITY_MEASURES_Version2.md`
- Incident response: `DOCS/docs_incident-runbook_Version4.md`

## Contact

For security concerns or encryption setup assistance:
- Email: katdevops099@gmail.com
- Repository Issues: [Create secure issue with encryption label]

---

**Last Updated**: 2025-11-10  
**Version**: 1.0  
**Owner**: KatXO / gamecentral720-collab
