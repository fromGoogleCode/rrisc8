/*
 * uart module
 * Copyright (C) 2011 WangMengyin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* UART 
 * UART module is similar to AT96S2313's UART, but has limited function.
 * REG define & address
 * UDR		(00_0000) |d7 d6 d5 d4 d3 d2 d1 d0|	(RW) UART Data register
 * UBRR		(00_0001) |r7 r6 r5 r4 r3 r2 r1 r0| (RW) UART baudrate register
 * UCR		(00_0010) |RXCIE TXCIE UDRIE THRU x x x x| (RW) UART control register
 * USR		(00_0011) |RXC TXC UDRE FE OR x x x| (RO) UART status register
*/
module uart #(
	parameter base_addr = 6'h0C,	   // UART I/O address = 0'b00_10xx
	parameter clk_freq = 10000000, // 10MHz CLK
	// Default 9600 baud, 8 data bit, 1 stop bit, no parity bit
	parameter baud = 9600
) (
	input sys_clk,
	input sys_rst,
	
	input [5:0] io_a,
	input io_we,
	input io_re,
	input [7:0] io_di,
	output reg [7:0] io_do,

	output rxc_irq, // rx complete INT
	output txc_irq, // tx complete INT
	output udr_irq, // tx data REG empty INT
	
	input txc_irq_ack, // irq ack for txc

	input uart_rx,
	output uart_tx

);

reg [7:0] UBRR; // UART bit rate register.
wire [7:0] rx_data; // UDR
wire [7:0] tx_data; // UDR
wire tx_wr, tx_done, tx_reg_empty, rx_rd, rx_done;
wire frame_error;
wire transceiver_rx;

uart_transceiver transceiver(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.uart_rx(transceiver_rx),
	.uart_tx(uart_tx),

	.divisor(UBRR),

	.rx_data(rx_data),
	.rx_done(rx_done),

	.tx_data(tx_data),
	.tx_wr(tx_wr),
	.tx_done(tx_done),
	.tx_reg_empty(tx_reg_empty), // 11-16

	.frame_error(frame_error)
);

assign transceiver_rx = THRU ? uart_tx : uart_rx;

/* CSR interface */
localparam udr_addr 	= base_addr;
localparam ubrr_addr 	= base_addr + 6'd1;
localparam ucr_addr 	= base_addr + 6'd2;
localparam usr_addr 	= base_addr + 6'd3;

wire csr_selected = (io_a == base_addr) | (io_a == ubrr_addr) | (io_a == ucr_addr) | (io_a == usr_addr);

assign tx_data = io_di;
assign tx_wr = (io_a == udr_addr) & io_we;
assign rx_rd = (io_a == udr_addr) & io_re;

localparam default_divisor = clk_freq/baud/16;

reg THRU;
reg break_en;
reg RXC, TXC, UDRE, OR; // refer to AT90S2313 Datasheet Page45~47
wire FE = frame_error; // frame_error is registered in uart_transceiver.v
reg RXCIE, TXCIE, UDRIE;

always @(posedge sys_clk, posedge sys_rst) begin
	if(sys_rst) begin
		io_do <= 8'd0;
		
		UBRR <= default_divisor;
		RXC <= 1'b0;
		TXC <= 1'b0;
		UDRE <= 1'b1;
		OR <= 1'b0;
		RXCIE <= 1'b0;
		TXCIE <= 1'b0;
		UDRIE <= 1'b0;
        THRU <= 1'b0;
	end else begin
		io_do <= 8'd0;
		
		// status bit operation
		RXC <= rx_done ? 1'b1 : (rx_rd ? 1'b0 : RXC);
		TXC <= tx_done ? 1'b1 : (txc_irq_ack ? 1'b0 : TXC); // modified 12-29
		UDRE <= tx_reg_empty; // modified 2012-01-03 // ? 1'b1 : (tx_wr ? 1'b0 : UDRE);
		OR <= rx_done ? 1'b1 : (rx_rd ? 1'b0 : OR); // ?
		if(csr_selected) begin
			if(io_re) begin // I/O read
				case(io_a) // io_do is registered.
					udr_addr	: io_do <= rx_data;
					ubrr_addr	: io_do <= UBRR;
					ucr_addr	: io_do <= {RXCIE, TXCIE, UDRIE, THRU, 4'd0}; // UCR
					usr_addr	: io_do <= {RXC, TXC, UDRE, FE, OR, 3'd0}; // USR
				endcase
            end
			if(io_we) begin // I/O write
				case(io_a)
					udr_addr	:; /* handled by transceiver */
					ubrr_addr	: UBRR <= io_di[7:0];
					ucr_addr	: {RXCIE, TXCIE, UDRIE, THRU} <= io_di[7:4];
					usr_addr	: // USR (RO)
					begin
						if(io_di[6])	TXC <= 1'b0; // clear txc when wirte '1' to it. 12-29
					end
				endcase
			end
		end
	end
end

// handle UART IRQ
assign rxc_irq = RXCIE & RXC;
assign txc_irq = TXCIE & TXC;
assign udr_irq = UDRIE & UDRE;

endmodule
