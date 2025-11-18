#!/bin/sh
set -e      # stop script as soon as something fails

CFILE=./passmgr     # C program lives here
VAULT=data/vault.enc  
ACCESS_LOG=data/access.log    

if [ $# -lt 1 ]; then
    echo "usage: passmgr.sh <command> [args]"
    exit 1
fi

if [ ! -x "$CFILE" ]; then
    make
fi

mkdir -p "$(dirname "$VAULT")" "$(dirname "$ACCESS_LOG")"

TMP=data/vault.tmp      
touch "$TMP"        
trap 'rm -f "$TMP"' EXIT       

CMD=$1      # capture the command before authentication

timestamp(){
    date +"%Y-%m-%d %H:%M:%S"
}

get_action_description(){
    case "$1" in
        add) echo "added to vault" ;;
        delete) echo "deleted from vault" ;;
        list) echo "listed vault contents" ;;
        search) echo "searched vault" ;;
        *) echo "accessed vault ($1)" ;;
    esac
}

log_access(){
    printf "VAULT ACCESSED ON $(timestamp) - %s\n" "$(get_action_description "$1")" >> "$ACCESS_LOG"
}

log_failure(){
    printf "VAULT ACCESS FAILED ON $(timestamp)\n">> "$ACCESS_LOG"
}

MAX_ATTEMPTS=5
ATTEMPTS=0

while true; do
    if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
        log_failure
        echo "Too many failed attempts! Exiting..."
        exit 1
    fi
    
    ATTEMPTS=$((ATTEMPTS + 1))
    printf "Master password: "
    stty -echo
    IFS= read PASS || exit 1        # clear internal field separator to allow passwords with spaces
    stty echo
    echo ""

    if [ -f "$VAULT" ]; then
        # decrypt existing vault into a temp file
        if openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d -salt -in "$VAULT" -out "$TMP" -pass pass:"$PASS" 2>/dev/null; then
            log_access "$CMD"
            break
        else
            echo "Incorrect password. You have $((MAX_ATTEMPTS - ATTEMPTS)) attempts left."
            unset PASS
        fi
    else
        log_access "$CMD"
        break
    fi
done

shift       # the rest of the args go to the C program

# run the C program on the plaintext file
if ! "$CFILE" "$CMD" "$TMP" "$@"; then      
    exit 1
fi

# encrypt the temporary file into the vault then check if it failed
if ! openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in "$TMP" -out "$VAULT" -pass pass:"$PASS"; then
    echo "encryption failed"
    exit 1
fi 

chmod 600 "$VAULT"      # give read(4) and write(2) permissions
rm -f "$TMP"        # remove the plaintext file now that we’re done # we already cleaned up, so drop the trap
unset PASS           # forget the password variable