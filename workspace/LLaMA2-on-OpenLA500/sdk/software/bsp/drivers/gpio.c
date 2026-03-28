#include "gpio.h"

unsigned long __attribute__((weak)) GPIO_BASE = 0xbf004000;

static inline unsigned int gpio_reg_read(unsigned int offset)
{
    return RegRead((unsigned int)(GPIO_BASE + offset));
}

static inline void gpio_reg_write(unsigned int offset, unsigned int value)
{
    RegWrite((unsigned int)(GPIO_BASE + offset), value);
}

void gpio_set_base(unsigned long base)
{
    GPIO_BASE = base;
}

unsigned long gpio_get_base(void)
{
    return GPIO_BASE;
}

void gpio_set_dir(U16 dir_mask)
{
    gpio_reg_write(GPIO_GPDIR_OFFSET, (unsigned int)dir_mask);
}

U16 gpio_get_dir(void)
{
    return (U16)(gpio_reg_read(GPIO_GPDIR_OFFSET) & 0xFFFFu);
}

void gpio_write_data(U16 value)
{
    gpio_reg_write(GPIO_GPDAT_OFFSET, (unsigned int)value);
}

U16 gpio_read_data(void)
{
    return (U16)(gpio_reg_read(GPIO_GPDAT_OFFSET) & 0xFFFFu);
}

void gpio_set_output_mask(U16 out_mask)
{
    gpio_set_dir((U16)(~out_mask));
}

void gpio_set_input_mask(U16 in_mask)
{
    gpio_set_dir(in_mask);
}

void gpio_irq_enable(int en)
{
    gpio_reg_write(GPIO_GPIEN_OFFSET, en ? 1u : 0u);
}

int gpio_irq_is_pending(void)
{
    return (int)(gpio_reg_read(GPIO_GPINT_OFFSET) & 0x1u);
}

void gpio_irq_clear(void)
{
    gpio_reg_write(GPIO_GPINT_OFFSET, 1u);
}
