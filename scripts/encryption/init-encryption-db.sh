#!/bin/bash
# Initialize PGP Encryption Database Submodule
# This script safely initializes the encryption database without exposing sensitive data

set -euo pipefail

ENCRYPTION_DB_PATH="encryption-db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔐 Initializing PGP Encryption Database Framework"
echo "=================================================="

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Error: git is not installed"
    exit 1
fi

cd "$REPO_ROOT"

# Check if .gitmodules exists
if [ ! -f .gitmodules ]; then
    echo "❌ Error: .gitmodules not found. Run this script from repository root."
    exit 1
fi

# Check if submodule is already initialized
if [ -d "$ENCRYPTION_DB_PATH/.git" ]; then
    echo "⚠️  Encryption database submodule already initialized"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📥 Updating encryption database submodule..."
        git submodule update --remote "$ENCRYPTION_DB_PATH"
    fi
else
    echo "📥 Initializing encryption database submodule..."
    
    # Prompt for the PGP repository URL
    echo ""
    echo "Enter your PGP encryption repository URL:"
    echo "Example: git@github.com:your-org/encryption-keys.git"
    read -p "URL: " PGP_REPO_URL
    
    if [ -z "$PGP_REPO_URL" ]; then
        echo "❌ Error: Repository URL cannot be empty"
        exit 1
    fi
    
    # Update .gitmodules with the actual URL
    git config -f .gitmodules submodule.encryption-db.url "$PGP_REPO_URL"
    
    # Initialize the submodule
    git submodule init
    git submodule update --depth 1
    
    echo "✅ Encryption database submodule initialized"
fi

# Set up security permissions
if [ -d "$ENCRYPTION_DB_PATH" ]; then
    echo "🔒 Setting secure permissions on encryption database..."
    chmod 700 "$ENCRYPTION_DB_PATH"
    echo "✅ Permissions set (read/write/execute for owner only)"
fi

# Create README if it doesn't exist
if [ ! -f "$ENCRYPTION_DB_PATH/README.md" ]; then
    echo "📝 Creating README.md in encryption database..."
    cat > "$ENCRYPTION_DB_PATH/README.md" << 'EOF'
# PGP Encryption Database

This directory contains encrypted keys and sensitive cryptographic material.

## Security Guidelines

1. **Never commit unencrypted keys** to this repository
2. **Always use GPG/PGP encryption** for all sensitive files
3. **Rotate keys regularly** according to your security policy
4. **Limit access** to this repository to authorized personnel only
5. **Audit access logs** regularly

## Structure

- `keys/` - Encrypted PGP keys
- `certs/` - Encrypted certificates
- `config/` - Encrypted configuration files

## Usage

All files should be encrypted before committing:
```bash
gpg --encrypt --recipient your-key-id sensitive-file
```

## Emergency Key Rotation

In case of compromise, follow the incident response procedure in:
`docs/incident-runbook.md`
EOF
    echo "✅ README.md created"
fi

echo ""
echo "=================================================="
echo "✅ Encryption database framework initialized"
echo ""
echo "📋 Next Steps:"
echo "1. Add your encrypted PGP keys to: $ENCRYPTION_DB_PATH/"
echo "2. Commit and push this configuration"
echo "3. Ensure team members have GPG configured"
echo "4. Review security measures in DOCS/SECURITY_MEASURES_Version2.md"
echo ""
echo "⚠️  Security Reminder:"
echo "   - The encryption-db/ directory is in .gitignore"
echo "   - Only encrypted files should be committed to the submodule"
echo "   - Never share private keys through this repository"
echo ""
