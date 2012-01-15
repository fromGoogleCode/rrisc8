#include <inttypes.h>
#include "../../include/ior8.h"
#include <avr/io.h>
#include <avr/interrupt.h>

#define BUF_SIZE	20

uint8_t isrecvcomplete(void);
void sendtouart(uint8_t , uint8_t*);
void receivefromuart(uint8_t , uint8_t );

uint8_t rxbuf[BUF_SIZE], txbuf[BUF_SIZE];
uint8_t txpos = 0, txlen = 0, rxpos = 0, rxlen = 0;

int main(void)
{	// serial port loopback using polling mode.
//	uart_puts("Hello world from rRISC v1.0.\n");
	UCR |= _BV(RXCIE) | _BV(TXCIE);
	sei();

	while(1) {
		PORTB = 0x00;
		receivefromuart(BUF_SIZE, 0);
		while(!isrecvcomplete());
		sendtouart(BUF_SIZE, rxbuf);
		PORTB = 0x00;
	}
}

uint8_t isrecvcomplete(void)
{
	return (rxlen == 0);
}

void sendtouart(uint8_t len, uint8_t *buf)
{
	int i;
	for(i=0; i < len; i++)
		txbuf[i] = buf[i];
	txpos = 0;
	txlen = len;
	UDR = txbuf[0];
	while(txlen >0);
}

void receivefromuart(uint8_t len, uint8_t bwait)
{
	rxpos = 0;
	rxlen = len;
	if(bwait)
		while(rxlen > 0);
}

// interrupt handle

ISR (UART_RX_vect)
{
	uint8_t c = UDR;
	if(rxlen-- > 0)
	{
		rxbuf[rxpos++] = c;
	}
	PORTB = 0x01;
}

ISR (UART_TX_vect)
{
	if(--txlen > 0)
	{
		UDR = txbuf[++txpos];
	}
	PORTB = 0x02;
}