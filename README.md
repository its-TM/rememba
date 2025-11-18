# Meet Rememba, your linux password manager.

A secure, command-line password manager built with C and shell scripting. Stores encrypted credentials locally using OpenSSL encryption.

## Features

### Core Operations
- **Add** passwords: Store service, username, and password entries
- **List** all entries: View all stored credentials
- **Search** entries: Filter entries by service name
- **Delete** entries: Remove entries by service name (removes all matching entries)

### Security Features
- **AES-256-CBC encryption** with PBKDF2 key derivation (100,000 iterations)
- **Master password protection**: All vault operations require authentication
- **Password attempt limiting**: Maximum 5 failed attempts before lockout
- **Hidden password input**: Passwords are not displayed while typing
- **Secure file permissions**: Vault file is set to `600` (read/write owner only)
- **Temporary file cleanup**: Plaintext files are automatically removed after operations

### Access Logging
- **Access log**: All successful vault accesses are logged with timestamps
- **Action tracking**: Logs include the specific action performed
- **Failed access logging**: Failed authentication attempts are also logged
- Log file: `data/access.log`

### Data Format
Entries are stored in pipe-delimited format: `service|username|password`

## Requirements

- Unix-like system (Linux, macOS, BSD)
- GCC compiler
- Make
- OpenSSL
- Standard Unix utilities (sh, stty, etc.)

> **Note**: The script automatically builds the C binary if it doesn't exist. No manual build step required.

## Usage

All operations are performed through the shell wrapper script, which handles encryption/decryption automatically:

```bash
# Add a new password entry
./passmgr.sh add <service> <username> <password>

# List all entries
./passmgr.sh list

# Search for entries by service
./passmgr.sh search <service>

# Delete all entries for a service
./passmgr.sh delete <service>
```

### Example Session

```bash
# Add an entry
./passmgr.sh add github alice mypassword123
Master password: [hidden input]

# List all entries
./passmgr.sh list
Master password: [hidden input]
github|alice|mypassword123

# Search for entries
./passmgr.sh search github
Master password: [hidden input]
github|alice|mypassword123

# Delete an entry
./passmgr.sh delete github
Master password: [hidden input]
```

## How It Works

1. **Authentication**: The script prompts for your master password
2. **Decryption**: If a vault exists, it's decrypted to a temporary file using OpenSSL
3. **Operation**: The C program performs the requested operation on the plaintext file
4. **Re-encryption**: The vault is re-encrypted and the temporary file is deleted
5. **Logging**: The access is logged with timestamp and action description

### Security Details

- **Encryption**: AES-256-CBC with PBKDF2 (100,000 iterations) and salt
- **Password storage**: Master password is never stored; only used for key derivation
- **Temporary files**: Plaintext is only in memory/temporary files during operations
- **File permissions**: Vault file (`data/vault.enc`) is restricted to owner read/write only
- **Error handling**: OpenSSL errors are suppressed for cleaner user experience

## File Structure

```
rememba/
├── src/
│   └── main.c          # C CLI program
├── data/
│   ├── vault.enc       # Encrypted password vault
│   └── access.log      # Access log with timestamps
├── passmgr             # Compiled binary
├── passmgr.sh          # Shell wrapper with encryption
├── Makefile            # Build configuration
└── README.md           # This file
```

## Access Log Format

The access log (`data/access.log`) records all vault operations:

```
VAULT ACCESSED ON 2024-01-15 14:30:45 - added to vault
VAULT ACCESSED ON 2024-01-15 14:31:12 - listed vault contents
VAULT ACCESSED ON 2024-01-15 14:32:00 - deleted from vault
VAULT ACCESSED ON 2024-01-15 14:33:20 - searched vault
VAULT ACCESS FAILED ON 2024-01-15 14:35:00
```

## Security Notes

- **Master password**: Choose a strong master password. If lost, the vault cannot be recovered.
- **Backup**: Regularly backup `data/vault.enc` to a secure location
- **Access log**: The access log is stored in plaintext for audit purposes
- **Multiple entries**: Deleting by service name removes ALL entries with that service name
- **Password attempts**: After 5 failed attempts, the script exits and logs the failure

## Troubleshooting

- **"encryption failed"**: Check disk space and file permissions
- **"decryption failed"**: Incorrect master password (you have 5 attempts)
- **"too many failed attempts"**: Wait and try again, or check your master password
- **Binary not found**: Run `make` to build the C program

## Development

The project consists of:
- **C program** (`src/main.c`): Handles vault operations on plaintext files
- **Shell script** (`passmgr.sh`): Manages encryption, authentication, and logging

The C program is intentionally simple and operates only on plaintext. All encryption/decryption is handled by the shell wrapper using OpenSSL.
