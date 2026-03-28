#ifndef _GPIO_H_
#define _GPIO_H_

#include "common_func.h"

extern unsigned long GPIO_BASE;

#define GPIO_GPDAT_OFFSET 0x00u
#define GPIO_GPDIR_OFFSET 0x04u
#define GPIO_GPIEN_OFFSET 0x08u
#define GPIO_GPINT_OFFSET 0x0Cu

/* Direction bit: 0 = output, 1 = input */
void gpio_set_base(unsigned long base);
unsigned long gpio_get_base(void);

void gpio_set_dir(U16 dir_mask);
U16 gpio_get_dir(void);

void gpio_write_data(U16 value);
U16 gpio_read_data(void);

void gpio_set_output_mask(U16 out_mask);
void gpio_set_input_mask(U16 in_mask);

void gpio_irq_enable(int en);
int gpio_irq_is_pending(void);
void gpio_irq_clear(void);

#endif
