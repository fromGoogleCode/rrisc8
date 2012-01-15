#include "../../include/ior8.h"
#include <avr/io.h>

void uart_putc(char);
char uart_getc(void);
void uart_puts(char *s);

int main(void)
{	// serial port loopback using polling mode.
	char c;
	uart_puts("Hello world from rRISC v1.0.\n");
	while(1) {
		c = uart_getc();
		uart_putc(c);
	}
}

void uart_putc(char c)
{
	loop_until_bit_is_set(USR, UDRE);
	UDR = (unsigned char)c;
}

void uart_puts(char *s)
{
	unsigned char c;
	while(c = *s++)
		uart_putc(c);
}

char uart_getc(void)
{
	loop_until_bit_is_set(USR, RXC);
	return UDR;
}