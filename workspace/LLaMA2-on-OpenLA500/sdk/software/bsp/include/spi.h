#ifndef _SPI_H_
#define _SPI_H_

#include "common_func.h"

extern unsigned long SPI_BASE;

#define SPI_CR1_OFFSET 0x00u
#define SPI_CR2_OFFSET 0x04u
#define SPI_SR_OFFSET  0x08u
#define SPI_DR_OFFSET  0x0Cu

#define SPI_SR_BSY_MASK  (1u << 7)
#define SPI_SR_TXE_MASK  (1u << 1)
#define SPI_SR_RXNE_MASK (1u << 0)

/* CR1 bits */
#define SPI_CR1_BIDIMODE (1u << 15)
#define SPI_CR1_BIDIOE   (1u << 14)
#define SPI_CR1_DFF      (1u << 11)
#define SPI_CR1_RXONLY   (1u << 10)
#define SPI_CR1_LSB      (1u << 7)
#define SPI_CR1_SPE      (1u << 6)

void spi_set_base(unsigned long base);
unsigned long spi_get_base(void);

void spi_write_cr1(U16 value);
U16 spi_read_cr1(void);

void spi_write_cr2(U8 value);
U8 spi_read_cr2(void);

U8 spi_read_sr(void);

void spi_write_dr(U16 value);
U16 spi_read_dr(void);

/* Basic master init, BR is [2:0], CPOL/CPHA are 0/1 */
void spi_init_master(U8 br, int cpol, int cpha);

/* Blocking transfer for simple polling use case */
U16 spi_transfer16(U16 tx_data);

#endif
