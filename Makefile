
# Super basic test Makefile


compile: main.elf

run: main.elf 
	qemu-arm main.elf

main.S:

main.out: main.S
	arm-none-eabi-as -mcpu=cortex-a8 -mfpu=vfpv2 -o main.out main.S
main.elf: main.out
	arm-none-eabi-ld main.out -o main.elf

clean:
	rm main.out main.elf

