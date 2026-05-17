CC      ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -Wpedantic -std=c99
PYTHON  ?= python3

# Default test range. Override with: make check START=2020 END=2030
START   ?= 2020
END     ?= 2030

OBJS    := patchtime.o

.PHONY: all check clean

all: patchtime_cli test_patchtime

patchtime.o: patchtime.c patchtime.h
	$(CC) $(CFLAGS) -c $< -o $@

patchtime_cli: patchtime_cli.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

test_patchtime: test_patchtime.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

check: test_patchtime gen_expected.py patchtime.py
	@echo "Comparing C output vs patchtime.py over $(START)..$(END)..."
	@diff <(./test_patchtime $(START) $(END)) \
	      <($(PYTHON) gen_expected.py $(START) $(END)) \
	  && echo "OK: C and Python agree on every date/anchor."

clean:
	rm -f patchtime.o patchtime_cli test_patchtime
