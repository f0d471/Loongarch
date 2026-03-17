#include "spi.h"

unsigned long __attribute__((weak)) SPI_BASE = 0xbf005000;

static inline unsigned int spi_reg_read(unsigned int offset)
{
    return RegRead((unsigned int)(SPI_BASE + offset));
}

static inline void spi_reg_write(unsigned int offset, unsigned int value)
{
    RegWrite((unsigned int)(SPI_BASE + offset), value);
}

void spi_set_base(unsigned long base)
{
    SPI_BASE = base;
}

unsigned long spi_get_base(void)
{
    return SPI_BASE;
}

void spi_write_cr1(U16 value)
{
    spi_reg_write(SPI_CR1_OFFSET, (unsigned int)value);
}

U16 spi_read_cr1(void)
{
    return (U16)(spi_reg_read(SPI_CR1_OFFSET) & 0xFFFFu);
}

void spi_write_cr2(U8 value)
{
    spi_reg_write(SPI_CR2_OFFSET, (unsigned int)value);
}

U8 spi_read_cr2(void)
{
    return (U8)(spi_reg_read(SPI_CR2_OFFSET) & 0xFFu);
}

U8 spi_read_sr(void)
{
    return (U8)(spi_reg_read(SPI_SR_OFFSET) & 0xFFu);
}

void spi_write_dr(U16 value)
{
    spi_reg_write(SPI_DR_OFFSET, (unsigned int)value);
}

U16 spi_read_dr(void)
{
    return (U16)(spi_reg_read(SPI_DR_OFFSET) & 0xFFFFu);
}

void spi_init_master(U8 br, int cpol, int cpha)
{
    U16 cr1 = 0;

    cr1 |= SPI_CR1_SPE;
    cr1 |= (U16)((br & 0x7u) << 3);
    if (cpol) {
        cr1 |= (1u << 1);
    }
    if (cpha) {
        cr1 |= (1u << 0);
    }

    spi_write_cr1(cr1);
    spi_write_cr2(0);
}

U16 spi_transfer16(U16 tx_data)
{
    unsigned int timeout;

    /* Wait until TX is empty */
    for (timeout = 0; timeout < 2000000u; timeout++) {
        if (spi_read_sr() & SPI_SR_TXE_MASK) {
            break;
        }
    }

    spi_write_dr(tx_data);

    /* Wait until RX is ready */
    for (timeout = 0; timeout < 2000000u; timeout++) {
        if (spi_read_sr() & SPI_SR_RXNE_MASK) {
            break;
        }
    }

    return spi_read_dr();
}
