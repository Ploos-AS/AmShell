CC = m68k-amigaos-gcc
PYTHON ?= python3

TARGET := build/AmShell
COMPAT_NATIVE_TARGET := build/CompatNative
SOURCES := src/main.c src/exec.c src/session.c

CPPFLAGS :=
CFLAGS ?= -Os -Wall -Wextra -Werror -m68000
LDFLAGS ?=

.PHONY: all clean check compat-prepare compat-bundle script-compat-bundle script-args-compat-bundle

all: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p build
	$(CC) $(CPPFLAGS) $(CFLAGS) $(SOURCES) $(LDFLAGS) -o $@

$(COMPAT_NATIVE_TARGET): tools/compat_native.c
	mkdir -p build
	$(CC) $(CPPFLAGS) $(CFLAGS) $< $(LDFLAGS) -o $@

check:
	$(PYTHON) tools/check_repo.py
	$(PYTHON) tests/test_compat_tools.py
	$(PYTHON) tests/test_script_compat.py
	$(PYTHON) tests/test_script_args_compat.py

compat-prepare:
	$(PYTHON) tools/compat_prepare.py

compat-bundle: $(TARGET) $(COMPAT_NATIVE_TARGET)
	$(PYTHON) tools/compat_bundle.py

script-compat-bundle: $(TARGET) $(COMPAT_NATIVE_TARGET)
	$(PYTHON) tools/script_compat_bundle.py

script-args-compat-bundle: $(TARGET) $(COMPAT_NATIVE_TARGET)
	$(PYTHON) tools/script_args_compat_bundle.py

clean:
	rm -rf build
