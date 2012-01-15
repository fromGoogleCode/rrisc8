#include "../../include/ior8.h"
#include <inttypes.h>
/*
 * Fibonacci calculate test
*/

uint8_t fib(uint8_t );

int main(void)
{
	DDRA = 0x00;
	DDRB = 0xFF;
	PORTB = 0x00;
	
	uint8_t result;
	
	result = fib(12);
	
	/* online calculator
	 * http://www.tools4noobs.com/online_tools/fibonacci/
	 */
	if(result == 144)	PORTB = 0x01;
	
	while(1) {
	}
}

uint8_t fib(uint8_t n)
{
	if(n == 1 || n == 2)
		return 1;
	else
		return fib(n-1) + fib(n-2);
}
