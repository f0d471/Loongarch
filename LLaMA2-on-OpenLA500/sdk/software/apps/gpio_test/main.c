#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gpio.h"

/* BSP globals used by existing runtime */
unsigned long UART_BASE = 0xbf000000;
unsigned long CB_BASE = 0xbf100000;
unsigned long CONFREG_TIMER_BASE = 0xbf20f100;
unsigned long CONFREG_CLOCKS_PER_SEC = 50000000L;
unsigned long CORE_CLOCKS_PER_SEC = 33000000L;

static void delay_loop(unsigned int n)
{
    volatile unsigned int i;
    for (i = 0; i < n; i++) {
        ;
    }
}

int main(int argc, char **argv)
{
    U16 pattern = 0x0001;
    int i;

    printf("\\n=== GPIO driver test start ===\\n");
    printf("GPIO base = 0x%08x\\n", (unsigned int)gpio_get_base());

    /* high 8 bits input, low 8 bits output */
    gpio_set_dir(0xFF00);
    printf("GPDIR = 0x%04x (1=input, 0=output)\\n", gpio_get_dir());

    gpio_irq_clear();
    gpio_irq_enable(1);

    for (i = 0; i < 16; i++) {
        gpio_write_data(pattern);
        printf("write GPDAT=0x%04x, readback=0x%04x, irq=%d\\n",
               pattern,
               gpio_read_data(),
               gpio_irq_is_pending());

        if (gpio_irq_is_pending()) {
            gpio_irq_clear();
            printf("irq cleared\\n");
        }

        pattern <<= 1;
        if (pattern == 0) {
            pattern = 1;
        }

        delay_loop(5000000);
    }

    gpio_irq_enable(0);
    printf("=== GPIO driver test done ===\\n");

    return 0;
}
