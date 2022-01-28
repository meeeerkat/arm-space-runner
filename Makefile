
# Super basic test Makefile


compile: bin/main.elf

run: bin/main.elf 
	qemu-arm bin/main.elf

main.s:
global_constants.s:
view.s:
lasers.s:
spaceship.s:


bin/view.out: view.s global_constants.s
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o bin/view.out view.s
bin/lasers.out: lasers.s global_constants.s
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o bin/lasers.out lasers.s
bin/spaceship.out: spaceship.s global_constants.s
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o bin/spaceship.out spaceship.s
bin/main.out: main.s global_constants.s
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o bin/main.out main.s

bin/main.elf: bin/main.out bin/view.out bin/lasers.out bin/spaceship.out
	arm-none-eabi-ld bin/*.out -o bin/main.elf

clean:
	rm bin/*.out bin/*.elf

