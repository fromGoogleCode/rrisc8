#include <inttypes.h>
#include "../../include/ior8.h"
#include <avr/io.h>
#define F_CPU	10000000UL // 10MHz
#include <util/delay.h>

/* I2C clock in Hz */
#define SCL_CLOCK  100000L
/* EEPROM address */
#define EEPROM_ADDR	0xA0
#define I2C_WRITE	0x00
#define I2C_READ	0x01

#define EEPROM_ERROR	-1

const uint8_t data2eeprom[10] = {0x55, 0xAA, 0x11, 0x22, 0x33, 
       							 0x44, 0xCC, 0x88, 0x99, 0x66};
#define EEPROM_BASE_ADDR	0x20

void i2c_init();
int16_t i2c_read(uint8_t dev_addr, uint8_t addr);
int16_t i2c_write(uint8_t dev_addr, uint8_t addr, uint8_t dat);

// uart dump
void uart_puts(char *s);
void dump_iic_value(uint8_t addr, uint16_t dat);

int main()
{
	uint8_t i = 0;
	int16_t dat;
	i2c_init();
	_delay_us(200);
	uart_puts("I2C EEPROM(24C02) read test.\n");
	while(i < 10) {
		i2c_write(EEPROM_ADDR, EEPROM_BASE_ADDR + i, data2eeprom[i]);
		_delay_ms(10);
		dat = i2c_read(EEPROM_ADDR, EEPROM_BASE_ADDR + i);
		_delay_ms(10);
		if(-1 == dat)
			uart_puts("Error.\n");
		else
			dump_iic_value(EEPROM_BASE_ADDR + i, dat);
		++i;
	}
	while(1);
}

// i2c operation
void i2c_init()
{
	uint16_t PRER;
	// set prescale register
	PRER = F_CPU/(5*SCL_CLOCK) - 1; // refer to i2c_specs.pdf page 7
	IICPRERLO = PRER & 0x00FF;
	IICPRERHI = PRER >> 8;
	
	IICCTR = _BV(IICE);
}

int16_t i2c_read(uint8_t dev_addr, uint8_t addr)
{
	IICTXR = dev_addr | I2C_WRITE;
	IICCR = _BV(STA) | _BV(WR);
	asm volatile("nop\n\t"::); // insert one NOP
	while(IICSR & _BV(TIP));
	asm volatile("nop\n\t"::);
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	
	IICTXR = addr;
	IICCR = _BV(WR);
	asm volatile("nop\n\t"::);
	while(IICSR & _BV(TIP));
	asm volatile("nop\n\t"::);
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	
	IICTXR = dev_addr | I2C_READ;
	IICCR = _BV(STA) | _BV(WR);
	asm volatile("nop\n\t"::);
	while(IICSR & _BV(TIP));
	asm volatile("nop\n\t"::);
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	
	IICCR = _BV(ACK) | _BV(RD) | _BV(STO);
	asm volatile("nop\n\t"::);
	while(IICSR & _BV(TIP));
	
	return IICRXR;
}

int16_t i2c_write(uint8_t dev_addr, uint8_t addr, uint8_t dat)
{
	IICTXR = dev_addr | I2C_WRITE;
	IICCR = _BV(STA) | _BV(WR);
	asm volatile("nop\n\t"::); // insert one NOP
	while(IICSR & _BV(TIP));
	asm volatile("nop\n\t"::); // insert one NOP
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	
	IICTXR = addr;
	IICCR = _BV(WR);
	asm volatile("nop\n\t"::); // insert one NOP
	while(IICSR & _BV(TIP));
	asm volatile("nop\n\t"::); // insert one NOP
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	
	IICTXR = dat;
	IICCR = _BV(WR) | _BV(STO);
	asm volatile("nop\n\t"::); // insert one NOP
	if(IICSR & _BV(RXACK)) return EEPROM_ERROR;
	return 1;
}


// uart dump
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

void dump_iic_value(uint8_t addr, uint16_t dat)
{
	char buf[20];
	uart_puts("Addr [0x");
	itoa(addr, buf);
	uart_puts(buf);
	uart_puts("]:\t");
	itoa(dat, buf);
	uart_puts("0x");
	uart_puts(buf);
	uart_putc('\n');
}

// hex
void itoa( int i,char* string) 
{
    int power, j, k;
    j = i; 
    for ( power = 1; j >= 16; j /= 16 ) 
      power*=16; 
    for (; power > 0; power /= 16 )
    {
		k = i / power;
        *string++ = k < 10 ? '0' + k : 'A' + k -10; 
        i %= power; 
    }
    *string='\0';
}