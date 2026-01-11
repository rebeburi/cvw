RISCV_PREFIX = /opt/cvw_toolchain/bin/riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJDUMP = $(RISCV_PREFIX)objdump
OBJCOPY = $(RISCV_PREFIX)objcopy
ARCH_FLAGS = -march=rv32gc -mabi=ilp32d -mcmodel=medany

sbst.objdump: sbst.elf
	$(OBJDUMP) -D sbst.elf > sbst.objdump

sbst.elf: sbst.S main.c crt0.s tests.h Makefile vectors.S
	$(CC) $(ARCH_FLAGS) -o sbst.elf \
	-nostartfiles -nostdlib -static -T../../link/link_sbst.ld \
	sbst.S main.c crt0.s vectors.S

# Added a .bin target as wsim often requires a raw binary or hex for gate-level memory pre-loading
sbst.bin: sbst.elf
	$(OBJCOPY) -O binary sbst.elf sbst.bin

	clean:
		rm -f sbst.elf sbst.objdump sbst.bin sbst.elf.* sbst_ram.*
