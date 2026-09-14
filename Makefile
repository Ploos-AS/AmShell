CC ?= m68k-amigaos-gcc
PYTHON ?= python3

TARGET := build/AmShell
SOURCES := src/main.c src/exec.c src/session.c

CPPFLAGS :=
CFLAGS ?= -Os -Wall -Wextra -Werror -m68000
LDFLAGS ?=

.PHONY: all clean check compat-prepare compat-bundle

all: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p build
	$(CC) $(CPPFLAGS) $(CFLAGS) $(SOURCES) $(LDFLAGS) -o $@

check:
	$(PYTHON) tools/check_repo.py
	$(PYTHON) tests/test_compat_tools.py

compat-prepare:
	$(PYTHON) tools/compat_prepare.py

compat-bundle:
	$(PYTHON) tools/compat_bundle.py

clean:
	rm -rf build
