CC=gcc
CFLAGS=-Wall -Wextra -pedantic -std=c11
LDFLAGS=

BIN=passmgr
SRC=src/main.c

.PHONY: all clean

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) -o $@ $(SRC) $(LDFLAGS)

clean:
	rm -f $(BIN)

