# pi_baremetal_qemu
This repository contains ARM assembly code designed for bare-metal programming on the Raspberry Pi 2B. It includes a printf implementation, as well as a simple scanf-implementation and some math functions

**Qemu starten mit:** 

                  qemu-system-arm -S -s -m 1024 -M raspi2b -monitor stdio -kernel kernel7.elf -smp 4,cores=1   

**Debuggen mit:** 
                  
                  gdb-multiarch

                  set architecture armv7
                  
                  file kernel7.elf
                  
                  target remote localhost:1234
