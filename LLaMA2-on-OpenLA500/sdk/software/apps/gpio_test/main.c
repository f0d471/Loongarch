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
#ifdef SIMU
    n = n / 100000u;
    if (n == 0) {
        n = 1;
    }
#endif
    volatile unsigned int i;
    for (i = 0; i < n; i++) {
        ;
    }
}

static void print_input_changes(U16 prev_inputs, U16 curr_inputs)
{
    U16 changed = (U16)(prev_inputs ^ curr_inputs);
    int bit;

    if (changed == 0) {
        return;
    }

    printf("gpio_in changed: old=0x%04x, new=0x%04x\n", prev_inputs, curr_inputs);

    for (bit = 0; bit < 16; bit++) {
        U16 mask = (U16)(1u << bit);

        if (changed & mask) {
            printf("  gpio_in[%d] -> %d\n", bit, (curr_inputs & mask) ? 1 : 0);
        }
    }
}

int main(int argc, char **argv)
{
    const U16 dir_mask = 0xFF00;
    const U16 out_mask = (U16)(~dir_mask);
    U16 pattern = 0x0001;
    U16 prev_inputs;

    (void)argc;
    (void)argv;

    setbuf(stdout, NULL);

    printf("\\n=== GPIO polling test start ===\\n");
    printf("GPIO base = 0x%08x\\n", (unsigned int)gpio_get_base());

    /* high 8 bits input, low 8 bits output */
    gpio_set_dir(dir_mask);
    printf("GPDIR = 0x%04x (1=input, 0=output)\\n", gpio_get_dir());

    gpio_write_data(0x0000);
    prev_inputs = (U16)(gpio_read_data() & dir_mask);
    printf("initial gpio_in = 0x%04x\\n", prev_inputs);

    for (;;) {
        U16 write_value = (U16)(pattern & out_mask);
        U16 readback;
        U16 curr_inputs;

        gpio_write_data(write_value);
        readback = gpio_read_data();
        curr_inputs = (U16)(readback & dir_mask);

        printf("write GPDAT=0x%04x, readback GPDAT=0x%04x\\n", write_value, readback);
        print_input_changes(prev_inputs, curr_inputs);
        prev_inputs = curr_inputs;

        pattern <<= 1;
        if (pattern > 0x0080) {
            pattern = 1;
        }

        delay_loop(5000000);
    }

    return 0;
}
