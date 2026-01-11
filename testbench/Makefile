%.memfile: %
	@echo "Processing $<..."
	@# Detect if ELF is 32-bit or 64-bit using grep on readelf output
	@CLASS=$$(riscv64-unknown-elf-readelf -h $< | grep "Class:" | awk '{print $$2}'); \
	if [ "$$CLASS" = "ELF32" ]; then \
		echo "Detected 32-bit ELF (x4)"; \
		OD_FLAGS="-t x4 -w4"; \
	else \
		echo "Detected 64-bit ELF (x8)"; \
		OD_FLAGS="-t x8 -w8"; \
	fi; \
	riscv64-unknown-elf-objcopy -O binary --adjust-vma=-0x80000000 $< $@.bin; \
	echo "@00000000" > $@; \
	od -An -v $$OD_FLAGS $@.bin | tr -d ' ' >> $@; \
	rm $@.bin

%.objdump.addr: %.objdump
	extractFunctionRadix.sh $<

%.objdump: %
	riscv64-unknown-elf-objdump -S -D $< > $@
