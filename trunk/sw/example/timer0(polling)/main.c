#include <inttypes.h>
#include "../../include/ior8.h"
#include <avr/io.h>

#define LED_ON 	PORTB |= 0x01
#define LED_OFF	PORTB &= 0xFE

int main(void)
{
	uint8_t i,j = 0;
	
	TCNT0 = 0;
	TCCR0 = 5;
	
	//GTCCR |= _BV(PSR10);
	
	while(1) {
		for(i = 0; i < 38; i++)	{ // 10,000,000/1024/256/38 = 1Hz about 1 second delay
			loop_until_bit_is_set(TIFR0, TOV0);
			TIFR0 |= _BV(TOV0);
		}
		
		if(j)
			LED_ON, j=0;
		else
			LED_OFF, j=1;
	}
}