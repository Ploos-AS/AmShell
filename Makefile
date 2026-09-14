CC ?= m68k-amigaos-gcc
PYTHON ?= python3

TARGET := build/AmShell
SOURCES := src/main.c

CPPFLAGS :=
CFLAGS ?= -Os -Wall -Wextra -Werror -m68000
LDFLAGS ?=

.PHONY: all clean check

all: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p build
	$(CC) $(CPPFLAGS) $(CFLAGS) $(SOURCES) $(LDFLAGS) -o $@

check:
	$(PYTHON) tools/check_repo.py

clean:
	rm -rf build
