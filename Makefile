
# Super basic test Makefile


compile: main.elf

run: main.elf 
	qemu-arm main.elf

main.s:
screen.s:
lazers.s:
spaceship.s:

main.out: main.s screen.s lasers.s spaceship.s
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o main.out main.s
main.elf: main.out
	arm-none-eabi-ld main.out -o main.elf

clean:
	rm main.out main.elf screen_management.out

