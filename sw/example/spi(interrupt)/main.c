#include <inttypes.h>
#include "../../include/ior8.h"
#include <avr/io.h>
#define F_CPU	10000000UL // 10MHz
#include <util/delay.h>
#include <avr/interrupt.h>

#define SPI_NCS_HIGH 	PORTC |= 0x01
#define SPI_NCS_LOW		PORTC &= 0xFE

//#define _DUMP_ADC_

uint8_t spi_transfer(uint8_t);

static uint8_t channel = 0;
static volatile uint8_t done = 0; // Keyword "volatile" can't be omitted. 

void uart_putc(char);
void uart_puts(char*);
void dump_adc_value(uint8_t, uint16_t);
void itoa( int i,char* string);

int main(void)
{	
	uint16_t adc_value;
	uint8_t i;
	SPIR = 0x01; // clock divider
	SPCR = _BV(SPE) | _BV(CPOL) | _BV(CPHA) | _BV(SPIE); // enable SPI
	SPI_NCS_HIGH;
	sei();

#ifdef _DUMP_ADC_	
	uart_puts("SPI ADC Demo. \n");
#endif	
	while(1) {
		for(channel = 0; channel < 8; channel++) {
#ifdef _DUMP_ADC_
		_delay_ms(500);
#endif
			SPI_NCS_LOW;
			adc_value = spi_transfer(channel << 3);
			adc_value = (adc_value & 0x0f) << 8;
			adc_value |= spi_transfer(0x00);
			SPI_NCS_HIGH;
#ifdef _DUMP_ADC_
			dump_adc_value(channel, adc_value);
#endif
		}
#ifdef _DUMP_ADC_
		for(i = 0; i < 5; i++)
			_delay_ms(500);
#endif
	}
	
	while(1)
		;
}

uint8_t spi_transfer(uint8_t data)
{
	done = 0;
	SPDR = data;
	while(!done) // waiting for interrupt (do something else here)
		;
	return SPDR;
}

ISR (SPI_STC_vect)
{
	done = 1;
}

// output adc value via uart
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

void dump_adc_value(uint8_t ch, uint16_t val)
{
	char buf[20];
	uart_puts("Channel [");
	uart_putc(ch + '0');
	uart_puts("]:\t");
	itoa(val, buf);
	uart_puts(buf);
	uart_putc('\n');
}

void itoa( int i,char* string) 
{
    int power, j;
    j = i; 
    for ( power = 1; j >= 10; j /= 10 ) 
      power*=10; 
    for (; power > 0; power /= 10 )
    {
        *string++ = '0' + i / power; 
        i %= power; 
    }
    *string='\0';
}