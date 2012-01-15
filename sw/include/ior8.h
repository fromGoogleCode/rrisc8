/* Copyright (c) 2011, WangMengyin
   All rights reserved. */

/* include/ior8.h - definitions for rRISC8 */
#ifndef _IOR8_H_
#define _IOR8_H_

#include <avr/sfr_defs.h>

/* I/O registers */

/* GPIO Register */
#define PINA	_SFR_IO8(0x00)
#define DDRA	_SFR_IO8(0x01)
#define PORTA	_SFR_IO8(0x02)

#define PINB	_SFR_IO8(0x03)
#define DDRB	_SFR_IO8(0x04)
#define PORTB	_SFR_IO8(0x05)


#define PINC	_SFR_IO8(0x06)
#define DDRC	_SFR_IO8(0x07)
#define PORTC	_SFR_IO8(0x08)

/*
#define PIND	_SFR_IO8(0x09)
#define DDRD	_SFR_IO8(0x0A)
#define PORTD	_SFR_IO8(0x0B)
*/

/* UART Register */
#define UDR		_SFR_IO8(0x0C)
#define UBRR	_SFR_IO8(0x0D)
#define UCR		_SFR_IO8(0x0E)
#define USR		_SFR_IO8(0x0F)

/* Prescale Register */
#define GTCCR	_SFR_IO8(0x10)

/* TIMER0 Register */
#define TCNT0	_SFR_IO8(0x11)
#define TCCR0	_SFR_IO8(0x12)
#define TIMSK0	_SFR_IO8(0x13)
#define TIFR0	_SFR_IO8(0x14)

/* SPI Register */
#define SPDR	_SFR_IO8(0x15)
#define SPIR	_SFR_IO8(0x16)
#define SPCR	_SFR_IO8(0x17)
#define SPSR	_SFR_IO8(0x18)

/* I2C Register */
#define IICPRERLO	_SFR_IO8(0x19)
#define IICPRERHI	_SFR_IO8(0x1A)
#define IICCTR	_SFR_IO8(0x1B)
#define IICTXR	_SFR_IO8(0x1C)
#define IICRXR	_SFR_IO8(0x1D)
#define IICCR	_SFR_IO8(0x1E)
#define IICSR	_SFR_IO8(0x1F)

/* Interrupt vectors */
/* External Interrupt Request 0 */
#define INT0_vect			_VECTOR(1)
#define SIG_INTERRUPT0			_VECTOR(1)

/* External Interrupt Request 1 */
#define INT1_vect			_VECTOR(2)
#define SIG_INTERRUPT1			_VECTOR(2)

///* Timer/Counter1 Capture Event */
//#define TIMER1_CAPT_vect		_VECTOR(3)
//#define SIG_INPUT_CAPTURE1		_VECTOR(3)
//
///* Timer/Counter1 Compare Match A */
//#define TIMER1_COMPA_vect		_VECTOR(4)
//#define SIG_OUTPUT_COMPARE1A	_VECTOR(4)
//
///* Timer/Counter1 Overflow */
//#define TIMER1_OVF_vect			_VECTOR(5)
//#define SIG_OVERFLOW1			_VECTOR(5)

/* I2C interrupt */
#define I2C_vect				_VECTOR(5)
#define SIG_I2C_SERIAL			_VECTOR(5)

/* Timer/Counter0 Overflow */
#define TIMER0_OVF_vect			_VECTOR(6)
#define SIG_OVERFLOW0			_VECTOR(6)

/* UART, Rx Complete */
#define UART_RX_vect            _VECTOR(7)

/* UART Data Register Empty */
#define UART_UDRE_vect          _VECTOR(8)

/* UART, Tx Complete */
#define UART_TX_vect            _VECTOR(9)

/* SPI, Transfer Complete */
#define SPI_STC_vect            _VECTOR(10)

#define _VECTORS_SIZE 22


/* PORTA */
#define PA7	7
#define PA6	6
#define PA5	5
#define PA4	4
#define PA3	3
#define PA2	2
#define PA1	1
#define PA0	0

/* DDRA */
#define DDA7	7
#define DDA6	6
#define DDA5	5
#define DDA4	4
#define DDA3	3
#define DDA2	2
#define DDA1	1
#define DDA0	0

/* PINA */
#define PINA7	7
#define PINA6	6
#define PINA5	5
#define PINA4	4
#define PINA3	3
#define PINA2	2
#define PINA1	1
#define PINA0	0

/* PORTB */
#define PB7	7
#define PB6	6
#define PB5	5
#define PB4	4
#define PB3	3
#define PB2	2
#define PB1	1
#define PB0	0

/* DDRB */
#define DDB7	7
#define DDB6	6
#define DDB5	5
#define DDB4	4
#define DDB3	3
#define DDB2	2
#define DDB1	1
#define DDB0	0

/* PINB */
#define PINB7	7
#define PINB6	6
#define PINB5	5
#define PINB4	4
#define PINB3	3
#define PINB2	2
#define PINB1	1
#define PINB0	0

/* PORTC */
#define PC7	7
#define PC6	6
#define PC5	5
#define PC4	4
#define PC3	3
#define PC2	2
#define PC1	1
#define PC0	0

/* DDRC */
#define DDC7	7
#define DDC6	6
#define DDC5	5
#define DDC4	4
#define DDC3	3
#define DDC2	2
#define DDC1	1
#define DDC0	0

/* PINC */
#define PINC7	7
#define PINC6	6
#define PINC5	5
#define PINC4	4
#define PINC3	3
#define PINC2	2
#define PINC1	1
#define PINC0	0

/* PORTD */
#define PD7	7
#define PD6	6
#define PD5	5
#define PD4	4
#define PD3	3
#define PD2	2
#define PD1	1
#define PD0	0

/* DDRD */
#define DDD7	7
#define DDD6	6
#define DDD5	5
#define DDD4	4
#define DDD3	3
#define DDD2	2
#define DDD1	1
#define DDD0	0

/* PIND */
#define PIND7	7
#define PIND6	6
#define PIND5	5
#define PIND4	4
#define PIND3	3
#define PIND2	2
#define PIND1	1
#define PIND0	0

/* UCR */
#define RXCIE	7
#define TXCIE	6
#define UDRIE	5
#define THRU	4

/* USR */
#define RXC		7
#define TXC		6
#define UDRE	5
#define FE		4
#define OR		3

/* GTCCR */
#define PSR10	0

/* TIMSK0 */
#define TOIE0	7

/* TIFR0 */
#define TOV0	7

/* SPCR */
#define CPHA	2
#define CPOL	3
#define SPE		6
#define SPIE	7

/* SPSR */
#define SPIF	7

/* IICCTR control register (WO) */
#define IICE	7	// IIC enable
#define IICIE	6	// IIC interrupt enable

/* IICCR command register (WO) */
#define STA		7	// IIC start condiction
#define STO		6	// IIC stop condiction
#define RD		5	// IIC read from slave
#define WR		4	// IIC write to slave
#define ACK		3	// send ACK or not1
#define IACK	0	// interrupt acknowledge, when set, clear pending interrupt


/* IICSR (RO) */
#define RXACK	7	// received acknowledge from slave
#define BUSY	6	// I2C bus is busy
#define AL		5	// Arbitration lost
#define TIP		1	// transfer in progress
#define IF		0	// interrupt acknowledge

#include <avr/common.h>
#include <avr/version.h>

#endif