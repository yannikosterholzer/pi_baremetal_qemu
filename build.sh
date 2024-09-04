arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mfpu=neon-vfpv4 -mcpu=cortex-a7 -c boot/boot.s -g -o build/boot.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c boot/vektor.s -g -o build/vektor.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard   -mfpu=neon-vfpv4 -mcpu=cortex-a7 -c kernel/kmain/main.s -g -o build/kmain.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kmem/kmem.s -g -o build/kmem.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kread/kread.s -g -o build/kread.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kscanf/kscan.s -g -o build/kscan.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kwrite/kwrite.s -g -o build/kwrite.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kprintf/kprintf.s -g -o build/kprintf.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard   -mfpu=neon-vfpv4 -mcpu=cortex-a7 -c kernel/klib/kformat/kformat.s -g -o build/kformat.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/kdrivers/gpu_mail.s -g -o build/gpu_mail.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/kdrivers/k_timer.s -g -o build/k_timer.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/kdrivers/k_uart0.s -g -o build/k_uart0.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/irq/irq_handler.s -g -o build/irq_handler.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kgraphics/kframebuff.s -g -o build/kframebuff.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mcpu=cortex-a7 -c kernel/klib/kgraphics/kcanvas.s -g -o build/kcanvas.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mfpu=neon-vfpv4 -mcpu=cortex-a7 -c kernel/klib/kmath/matrix.s -g -o build/matrix.o
arm-none-eabi-as -march=armv7-a -mfloat-abi=hard  -mfpu=neon-vfpv4 -mcpu=cortex-a7 -c kernel/klib/kmath/trigono.s -g -o build/trigono.o

cd build
arm-none-eabi-ld -g  neon-test.o boot.o vektor.o kmain.o kprintf.o kcanvas.o kread.o kmem.o gpu_mail.o kframebuff.o k_timer.o kformat.o k_uart0.o kwrite.o kscan.o irq_handler.o matrix.o trigono.o -T link.lds -o out/kernel7.elf --print-map > out/log/kernel_map.s
cd out/
arm-none-eabi-objcopy kernel7.elf -g -O binary kernel7.img
arm-none-eabi-objdump -D kernel7.elf > log/kernel_disasm.s

