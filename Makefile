ARCH = $(shell uname -m)
NASM = nasm
NASMFLAGS = -felf32
LDFLAGS = -melf_i386

all:
	@echo 'Error, target not specified.'
	@make --no-print-directory help

help:
	@echo 'Usage:'
	@echo '	To assemble %.asm	`make %.o`'
	@echo '	To link %.o		`make %`'
	@echo '	Assemble and link %.asm	`make %`'
	@echo '	To clean up		`make clean`'

%.o: %.asm
	$(NASM) $(NASMFLAGS) $^ -o $@

%: %.o
	$(LD) $(LDFLAGS) $^ $(LDLIBS) -o $@

clean:
	find . -mindepth 1 -maxdepth 1 -executable -type f -delete
