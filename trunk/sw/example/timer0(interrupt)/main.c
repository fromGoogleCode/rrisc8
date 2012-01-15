#include <inttypes.h>
#include "../../include/ior8.h"
#include <avr/io.h>
#include <avr/interrupt.h>

#define LED_ON 	PORTB |= 0x01
#define LED_OFF	PORTB &= 0xFE

static uint8_t cnt = 0;
static uint8_t j = 0;

int main(void)
{
	
	TCNT0 = 0;
	TCCR0 = 5;
	TIMSK0 = _BV(TOIE0);
	sei();

	while(1);
}

ISR (TIMER0_OVF_vect)
{
	if(++cnt > 37) {
		if(j)
			LED_ON, j=0;
		else
			LED_OFF, j=1;
		cnt = 0;
	}
}