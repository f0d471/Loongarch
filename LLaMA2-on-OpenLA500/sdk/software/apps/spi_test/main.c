#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spi.h"

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
    U16 tx = 0x00A5;

    (void)argc;
    (void)argv;

    setbuf(stdout, NULL);

    printf("\n=== SPI register/transfer test start ===\n");
    printf("SPI base = 0x%08x\n", (unsigned int)spi_get_base());

    spi_init_master(2, 0, 0);

    printf("CR1 = 0x%04x\n", spi_read_cr1());
    printf("CR2 = 0x%02x\n", spi_read_cr2());
    printf("SR  = 0x%02x\n", spi_read_sr());

    for (;;) {
        U16 rx = spi_transfer16(tx);
        U8 sr = spi_read_sr();

        printf("tx=0x%04x, rx=0x%04x, sr=0x%02x\n", tx, rx, sr);

        tx = (U16)((tx << 1) | (tx >> 15));
        delay_loop(3000000u);
    }

    return 0;
}
