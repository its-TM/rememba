# Password Manager

Simple Unix password manager using a C CLI and OpenSSL-based file encryption.

## Requirements

- Unix-like system with GCC, make, OpenSSL, core utils

## Build

```
make
```

## Usage

Run commands through the shell wrapper so entries stay encrypted:

```
./scripts/passmgr.sh add service user secret
./scripts/passmgr.sh list
./scripts/passmgr.sh search service
./scripts/passmgr.sh delete service
```

The script prompts for the master password, decrypts `data/vault.enc` into a temporary file, runs the C CLI, and re-encrypts the vault. The plaintext file never persists after the command finishes.

## CLI reference

```
./passmgr add <vault-file> <service> <user> <password>
./passmgr list <vault-file>
./passmgr search <vault-file> <term>
./passmgr delete <vault-file> <service>
```

The C program operates on plaintext, so use the script to manage the encrypted store.

## Testing

1. Build the CLI with `make`.
2. Run `./scripts/passmgr.sh add demo alice hunter2`.
3. Run `./scripts/passmgr.sh list` to verify the entry.
4. Run `./scripts/passmgr.sh search demo` to filter results.
5. Run `./scripts/passmgr.sh delete demo` and list again to confirm removal.
6. Attempt to open `data/vault.enc` with `cat data/vault.enc` to ensure contents remain unreadable.

