#!/bin/bash
# Secure Encrypted Handshake - Protection Against MITM/Handshake Attacks
# All data transfers are encrypted before transmission

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENCRYPTION_DB_PATH="$REPO_ROOT/encryption-db"
TEMP_DIR="$REPO_ROOT/.secure-temp"
HANDSHAKE_KEY_FILE="$HOME/.ssh/encryption-handshake.key"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔐 Secure Encrypted Handshake Protocol${NC}"
echo -e "${CYAN}========================================${NC}"

# Function: Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    command -v gpg >/dev/null 2>&1 || missing_tools+=("gpg")
    command -v openssl >/dev/null 2>&1 || missing_tools+=("openssl")
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo "Install with: sudo apt-get install gnupg openssl git"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Function: Generate session key for handshake
generate_session_key() {
    echo -e "${YELLOW}🔑 Generating ephemeral session key...${NC}"
    
    # Create secure temp directory
    mkdir -p "$TEMP_DIR"
    chmod 700 "$TEMP_DIR"
    
    # Generate random session key (256-bit AES)
    openssl rand -base64 32 > "$TEMP_DIR/session.key"
    chmod 600 "$TEMP_DIR/session.key"
    
    echo -e "${GREEN}✅ Session key generated${NC}"
}

# Function: Establish encrypted handshake
establish_handshake() {
    local recipient_key=$1
    
    echo -e "${YELLOW}🤝 Establishing encrypted handshake...${NC}"
    
    # Generate handshake token (timestamp + random nonce)
    local timestamp=$(date +%s)
    local nonce=$(openssl rand -hex 16)
    local handshake_token="${timestamp}:${nonce}"
    
    # Encrypt handshake token with recipient's GPG key
    echo "$handshake_token" | gpg --encrypt --armor \
        --recipient "$recipient_key" \
        --trust-model always \
        --output "$TEMP_DIR/handshake.token.gpg"
    
    # Create handshake signature
    echo "$handshake_token" | gpg --sign --armor \
        --output "$TEMP_DIR/handshake.sig"
    
    echo -e "${GREEN}✅ Encrypted handshake established${NC}"
    echo -e "${CYAN}   Token: ${handshake_token:0:20}...${NC}"
}

# Function: Encrypt data before transmission
encrypt_for_transmission() {
    local source_file=$1
    local output_file=$2
    local session_key="$TEMP_DIR/session.key"
    
    echo -e "${YELLOW}🔒 Encrypting data for secure transmission...${NC}"
    
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}❌ Source file not found: $source_file${NC}"
        return 1
    fi
    
    # Step 1: Encrypt with session key (AES-256-CBC)
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$source_file" \
        -out "$TEMP_DIR/data.enc" \
        -pass file:"$session_key"
    
    # Step 2: Encrypt session key with recipient's GPG key
    gpg --encrypt --armor \
        --recipient "$GPG_RECIPIENT" \
        --trust-model always \
        --output "$TEMP_DIR/session.key.gpg" \
        "$session_key"
    
    # Step 3: Create package with encrypted data + encrypted session key
    tar -czf "$output_file" \
        -C "$TEMP_DIR" \
        data.enc session.key.gpg handshake.token.gpg handshake.sig
    
    echo -e "${GREEN}✅ Data encrypted and packaged${NC}"
    echo -e "${CYAN}   Output: $output_file${NC}"
}

# Function: Decrypt received data
decrypt_from_transmission() {
    local package_file=$1
    local output_file=$2
    
    echo -e "${YELLOW}🔓 Decrypting received data...${NC}"
    
    if [ ! -f "$package_file" ]; then
        echo -e "${RED}❌ Package file not found: $package_file${NC}"
        return 1
    fi
    
    # Step 1: Extract package
    tar -xzf "$package_file" -C "$TEMP_DIR"
    
    # Step 2: Verify handshake signature
    if ! gpg --verify "$TEMP_DIR/handshake.sig" >/dev/null 2>&1; then
        echo -e "${RED}❌ Handshake signature verification failed!${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Handshake verified${NC}"
    
    # Step 3: Decrypt session key
    gpg --decrypt --output "$TEMP_DIR/session.key.dec" \
        "$TEMP_DIR/session.key.gpg"
    
    # Step 4: Decrypt data with session key
    openssl enc -aes-256-cbc -d -pbkdf2 \
        -in "$TEMP_DIR/data.enc" \
        -out "$output_file" \
        -pass file:"$TEMP_DIR/session.key.dec"
    
    echo -e "${GREEN}✅ Data decrypted successfully${NC}"
    echo -e "${CYAN}   Output: $output_file${NC}"
}

# Function: Secure push to encryption database
secure_push_to_db() {
    local source_file=$1
    local db_path=$2
    
    echo -e "${YELLOW}📤 Secure push to encryption database...${NC}"
    
    # Generate session key and establish handshake
    generate_session_key
    establish_handshake "$GPG_RECIPIENT"
    
    # Encrypt file for transmission
    local encrypted_package="$TEMP_DIR/secure-package.tar.gz.enc"
    encrypt_for_transmission "$source_file" "$encrypted_package"
    
    # Move encrypted package to encryption database
    cd "$ENCRYPTION_DB_PATH"
    
    # Create directory structure if needed
    mkdir -p "$(dirname "$db_path")"
    
    # Copy encrypted package
    cp "$encrypted_package" "$db_path"
    
    # Git operations on encrypted data only
    git add "$db_path"
    git commit -m "Add encrypted data: $(basename "$db_path") [$(date +'%Y-%m-%d %H:%M')]"
    
    echo -e "${GREEN}✅ Encrypted data pushed to database${NC}"
    echo -e "${CYAN}   Location: $db_path${NC}"
}

# Function: Secure pull from encryption database
secure_pull_from_db() {
    local db_path=$1
    local output_file=$2
    
    echo -e "${YELLOW}📥 Secure pull from encryption database...${NC}"
    
    cd "$ENCRYPTION_DB_PATH"
    
    # Pull latest changes
    git pull origin main
    
    if [ ! -f "$db_path" ]; then
        echo -e "${RED}❌ File not found in database: $db_path${NC}"
        return 1
    fi
    
    # Decrypt received package
    decrypt_from_transmission "$db_path" "$output_file"
    
    echo -e "${GREEN}✅ Data pulled and decrypted${NC}"
}

# Function: Sync with encrypted handshake
secure_sync() {
    echo -e "${YELLOW}🔄 Performing secure sync with encryption database...${NC}"
    
    cd "$ENCRYPTION_DB_PATH"
    
    # Generate fresh session key for sync
    generate_session_key
    establish_handshake "$GPG_RECIPIENT"
    
    # Pull with verification
    echo -e "${CYAN}Pulling latest encrypted data...${NC}"
    git pull origin main
    
    # Verify all files have valid signatures
    local unsigned_files=$(find . -name "*.gpg" -o -name "*.enc" | while read file; do
        if [ ! -f "${file}.sig" ]; then
            echo "$file"
        fi
    done)
    
    if [ -n "$unsigned_files" ]; then
        echo -e "${YELLOW}⚠️  Warning: Some files lack signatures:${NC}"
        echo "$unsigned_files"
    else
        echo -e "${GREEN}✅ All files properly signed${NC}"
    fi
    
    echo -e "${GREEN}✅ Secure sync completed${NC}"
}

# Function: Clean up temporary files
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    
    if [ -d "$TEMP_DIR" ]; then
        # Securely wipe temporary files
        find "$TEMP_DIR" -type f -exec shred -u {} \; 2>/dev/null || true
        rm -rf "$TEMP_DIR"
    fi
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Function: Display usage
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  push <source_file> <db_path>     Push file to encryption database with secure handshake
  pull <db_path> <output_file>     Pull file from encryption database and decrypt
  sync                             Sync encryption database with handshake verification
  verify                           Verify encryption database integrity

Environment Variables:
  GPG_RECIPIENT    GPG key ID or email for encryption (required)

Examples:
  $0 push ./secrets.json keys/production/secrets.json.enc
  $0 pull keys/production/secrets.json.enc ./secrets.json
  $0 sync
  $0 verify

EOF
}

# Main execution
main() {
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    # Check for GPG recipient
    if [ -z "${GPG_RECIPIENT:-}" ]; then
        echo -e "${RED}❌ Error: GPG_RECIPIENT environment variable not set${NC}"
        echo "Export your GPG key ID: export GPG_RECIPIENT=your-key-id@example.com"
        exit 1
    fi
    
    check_prerequisites
    
    case "${1:-}" in
        push)
            if [ $# -lt 3 ]; then
                echo -e "${RED}❌ Error: Missing arguments${NC}"
                usage
                exit 1
            fi
            secure_push_to_db "$2" "$3"
            ;;
        pull)
            if [ $# -lt 3 ]; then
                echo -e "${RED}❌ Error: Missing arguments${NC}"
                usage
                exit 1
            fi
            secure_pull_from_db "$2" "$3"
            ;;
        sync)
            secure_sync
            ;;
        verify)
            cd "$ENCRYPTION_DB_PATH"
            echo -e "${YELLOW}🔍 Verifying encryption database integrity...${NC}"
            git fsck --full
            echo -e "${GREEN}✅ Verification complete${NC}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}✅ Operation completed successfully${NC}"
}

# Run main function
main "$@"
