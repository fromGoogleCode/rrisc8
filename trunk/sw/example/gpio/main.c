#include "../../include/ior8.h"

int main(void)
{
	DDRA = 0x00;
	DDRB = 0xFF;
	
	while(1) {
			PORTB = 0xff;
	}
}