#include "wdt.h"

unsigned long __attribute__((weak)) WDT_BASE = 0xbf006000;

static inline unsigned int wdt_reg_read(unsigned int offset)
{
    return RegRead((unsigned int)(WDT_BASE + offset));
}

static inline void wdt_reg_write(unsigned int offset, unsigned int value)
{
    RegWrite((unsigned int)(WDT_BASE + offset), value);
}

void wdt_set_base(unsigned long base)
{
    WDT_BASE = base;
}

unsigned long wdt_get_base(void)
{
    return WDT_BASE;
}

void wdt_set_load(U32 load_value)
{
    if (load_value == 0u) {
        load_value = 1u;
    }
    wdt_reg_write(WDT_LOAD_OFFSET, (unsigned int)load_value);
}

U32 wdt_get_load(void)
{
    return (U32)wdt_reg_read(WDT_LOAD_OFFSET);
}

U32 wdt_get_count(void)
{
    return (U32)wdt_reg_read(WDT_COUNT_OFFSET);
}

U32 wdt_get_status(void)
{
    return (U32)(wdt_reg_read(WDT_STATUS_OFFSET) & 0x3u);
}

void wdt_enable(int en)
{
    unsigned int ctrl = en ? WDT_CTRL_EN_MASK : 0u;
    wdt_reg_write(WDT_CTRL_OFFSET, ctrl);
}

void wdt_irq_enable(int en)
{
    unsigned int ctrl = WDT_CTRL_EN_MASK;

    if (en) {
        ctrl |= WDT_CTRL_IRQ_EN_MASK;
    }

    wdt_reg_write(WDT_CTRL_OFFSET, ctrl);
}

void wdt_clear_irq(void)
{
    wdt_reg_write(WDT_CTRL_OFFSET, WDT_CTRL_EN_MASK | WDT_CTRL_CLR_IRQ_MASK);
}

void wdt_clear_res(void)
{
    wdt_reg_write(WDT_CTRL_OFFSET, WDT_CTRL_EN_MASK | WDT_CTRL_CLR_RES_MASK);
}

void wdt_clear_count(void)
{
    wdt_reg_write(WDT_CTRL_OFFSET, WDT_CTRL_EN_MASK | WDT_CTRL_CLR_COUNT_MASK);
}
