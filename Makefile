AS=arm-none-eabi-as
ASFLAGS=-mcpu=cortex-a8 -mfpu=vfpv2
ASLD=arm-none-eabi-ld
ASLDFLAGS=

TEST_FILES_NAME=random_generator
S_GLOBAL_FILES_NAME=global_constants tick_macros
S_FILES_NAME=main random_generator view time inputs general_inputs lasers spaceship
EXEC_FILES_NAME=main

SRC_GLOBAL_FILES=$(patsubst %, src/%.s, $(S_GLOBAL_FILES_NAME))
SRC_TEST_FILES=$(patsubst %, src/tests/%.s, $(TEST_FILES_NAME))
SRC_FILES=$(patsubst %, src/%.s, $(S_FILES_NAME))
OBJ_TEST_FILES=$(patsubst %, obj/tests/%.out, $(TEST_FILES_NAME))
OBJ_FILES=$(patsubst %, obj/%.out, $(S_FILES_NAME))
EXEC_TEST_FILES=$(patsubst %, bin/tests/%.elf, $(TEST_FILES_NAME))
EXEC_FILES=$(patsubst %, bin/%.elf, $(EXEC_FILES_NAME))

compile: $(EXEC_FILES) $(EXEC_TEST_FILES)

run: compile
	qemu-arm $(EXEC_FILES)
tests: compile
	qemu-arm $(EXEC_TEST_FILES)

$(SRC_FILES):
$(SRC_TEST_FILES):

$(OBJ_FILES): obj/%.out : $(SRC_GLOBAL_FILES) src/%.s
	$(AS) $(ASFLAGS) $^ -o $@
$(OBJ_TEST_FILES): obj/tests/%.out : src/tests/%.s
	$(AS) $(ASFLAGS) $^ -o $@

$(EXEC_FILES): $(OBJ_FILES)
	$(ASLD) $(ASLDFLAGS) $^ -o $@
$(EXEC_TEST_FILES): bin/tests/%.elf : obj/%.out obj/tests/%.out
	$(ASLD) $(ASLDFLAGS) $^ -o $@


.PHONY: clean
clean:
	rm $(EXEC_FILES) $(EXEC_TEST_FILES) $(OBJ_FILES) $(OBJ_TEST_FILES)

