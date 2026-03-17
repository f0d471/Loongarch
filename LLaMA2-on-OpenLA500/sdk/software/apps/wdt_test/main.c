#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wdt.h"

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

int main(int argc, char **argv)
{
    U32 status_prev = 0;

    (void)argc;
    (void)argv;

    setbuf(stdout, NULL);

    printf("\n=== WDT polling test start ===\n");
    printf("WDT base = 0x%08x\n", (unsigned int)wdt_get_base());

    /* Small load for easy timeout observation */
    wdt_set_load(200000u);
    printf("load = %u\n", (unsigned int)wdt_get_load());

    wdt_irq_enable(1);
    wdt_clear_count();

    for (;;) {
        U32 cnt = wdt_get_count();
        U32 status = wdt_get_status();

        printf("count=%u, status=0x%08x\n", (unsigned int)cnt, (unsigned int)status);

        if (((status ^ status_prev) & WDT_STATUS_IRQ_MASK) != 0u) {
            printf("WDT IRQ flag changed -> %u\n", (unsigned int)((status & WDT_STATUS_IRQ_MASK) ? 1u : 0u));
        }

        if (((status ^ status_prev) & WDT_STATUS_RES_MASK) != 0u) {
            printf("WDT RES flag changed -> %u\n", (unsigned int)((status & WDT_STATUS_RES_MASK) ? 1u : 0u));
        }

        if (status & WDT_STATUS_IRQ_MASK) {
            wdt_clear_irq();
        }

        if (status & WDT_STATUS_RES_MASK) {
            wdt_clear_res();
            wdt_clear_count();
        }

        status_prev = status;
        delay_loop(1000000u);
    }

    return 0;
}
