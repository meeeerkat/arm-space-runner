AS=arm-none-eabi-as
ASFLAGS=-mcpu=cortex-a8 -mfpu=vfpv2
ASLD=arm-none-eabi-ld
ASLDFLAGS=

S_GLOBAL_FILES_NAME=globals.s
S_FILES_NAME=main.s time.s view.s lasers.s spaceship.s

SRC_GLOBAL_FILES=$(patsubst %.s, src/%.s, $(S_GLOBAL_FILES_NAME))
SRC_FILES=$(patsubst %.s, src/%.s, $(S_FILES_NAME))
OBJ_FILES=$(patsubst %.s, obj/%.out, $(S_FILES_NAME))
EXEC_FILES=bin/main.elf


compile: $(EXEC_FILES)

run: $(EXEC_FILES)
	qemu-arm $(EXEC_FILES)

obj/%.out: src/%.s $(SRC_GLOBAL_FILES)
	$(AS) $(ASFLAGS) $< -o $@

bin/%.elf: $(OBJ_FILES)
	$(ASLD) $(ASLDFLAGS) $(OBJ_FILES) -o $@


.PHONY: clean
clean:
	rm $(EXEC_FILES)

