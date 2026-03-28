#ifndef _WDT_H_
#define _WDT_H_

#include "common_func.h"

extern unsigned long WDT_BASE;

#define WDT_CTRL_OFFSET   0x00u
#define WDT_LOAD_OFFSET   0x04u
#define WDT_COUNT_OFFSET  0x08u
#define WDT_STATUS_OFFSET 0x0Cu

#define WDT_CTRL_EN_MASK        (1u << 0)
#define WDT_CTRL_IRQ_EN_MASK    (1u << 1)
#define WDT_CTRL_CLR_IRQ_MASK   (1u << 2)
#define WDT_CTRL_CLR_RES_MASK   (1u << 3)
#define WDT_CTRL_CLR_COUNT_MASK (1u << 4)

#define WDT_STATUS_IRQ_MASK (1u << 0)
#define WDT_STATUS_RES_MASK (1u << 1)

void wdt_set_base(unsigned long base);
unsigned long wdt_get_base(void);

void wdt_set_load(U32 load_value);
U32 wdt_get_load(void);
U32 wdt_get_count(void);
U32 wdt_get_status(void);

void wdt_enable(int en);
void wdt_irq_enable(int en);
void wdt_clear_irq(void);
void wdt_clear_res(void);
void wdt_clear_count(void);

#endif
