#!/bin/sh                     # tell Unix to run this with /bin/sh
set -e                        # stop the script as soon as something fails

CFILE=./passmgr                 # where the C program lives
VAULT=data/vault.enc          # the encrypted vault file

if [ $# -lt 1 ]; then         # need at least one command (add/list/etc.)
    echo "usage: passmgr.sh <command> [args]"
    exit 1
fi

if [ ! -x "$CFILE" ]; then      # if the C program is missing, build it
    make
fi

echo -n "Master password: "   # ask for the password without a newline
stty -echo                    # hide what the user types
IFS= read PASS                # read the password into PASS
stty echo                     # turn echo back on
echo ""                       # print a newline so the terminal looks normal

TMP=data/vault.tmp               # use a fixed temp file path
touch "$TMP"                     # create it with touch
trap 'rm -f "$TMP"' EXIT          # make sure it gets deleted when we exit

if [ -f "$VAULT" ]; then          # if we already have an encrypted vault
    if ! openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d -salt \
        -in "$VAULT" -out "$TMP" -pass pass:"$PASS"
    then
        echo "decryption failed"
        exit 1
    fi
fi

CMD=$1                            # remember the subcommand (add/list/...)
shift                              # the rest of the args go to the C program

if ! "$CFILE" "$CMD" "$TMP" "$@"; then   # run the C program on the plaintext file
    exit 1
fi

if ! openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
    -in "$TMP" -out "$VAULT" -pass pass:"$PASS"
then
    echo "encryption failed"
    exit 1
fi

chmod 600 "$VAULT"   # lock down the vault file’s permissions
rm -f "$TMP"         # remove the plaintext file now that we’re done
trap - EXIT          # we already cleaned up, so drop the trap
unset PASS           # forget the password variable