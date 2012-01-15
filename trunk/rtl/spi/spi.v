/*
 * rAVR SPI
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
 // 2011-11-19 create Ver 1.0.0
 
 /*
 * refer to ATMega48's Datasheet, page 168~170. 
 * REG define & address
 * SPDR		(00_1000) |d7 d6 d5 d4 d3 d2 d1 d0|	(RW) SPI Data register
 * SPIR		(00_1001) |x x x x r3 r2 r1 r0| (RW) SPI clock divider register
 * SPCR		(00_1010) |SPIE SPE x x CPOL CPHA x x| (RW) SPI control register
 * SPSR		(00_1011) |SPIF x x x x x x x| (RO) UART status register
 * note: SPI Controller clear SPIF once porocessor enters SPI interrupt 
 *       or program reads SPSR.
 */
module spi #(
	parameter base_addr = 6'h15
) (
	input sys_clk,
	input sys_rst,
	
	input [5:0] io_a,
	input io_we,
	input io_re,
	input [7:0] io_di,
	output reg [7:0] io_do,

	output wire spi_irq, // spi transfer complete INT
	input wire spi_irq_ack, // interrupt handler ACK, used to clear SPIF

	input wire spi_miso,
	output wire spi_mosi,
	output wire spi_sck
);
 
localparam spdr_addr 	= base_addr;
localparam spir_addr	= base_addr + 6'd1;
localparam spcr_addr	= base_addr + 6'd2;
localparam spsr_addr	= base_addr + 6'd3; 
 
reg [3:0] SPIR; // 4-bit CLOCK didiver
reg SPIE, SPE, CPOL, CPHA, SPIF;
wire [7:0] tx_data, rx_data; // spi tx data
reg [7:0] rx_data_reg; // spi rx REG
wire tx_wr, spsr_rd, spi_done;
 
spi_transceiver transceiver(
	.sys_rst(sys_rst),
	.sys_clk(sys_clk),
	
	.spi_miso(spi_miso),
	.spi_mosi(spi_mosi),
	.spi_sck(spi_sck),
	
	.divisor(SPIR),
	
	.spi_enable(SPE),
	
	.rx_data(rx_data),

	.tx_data(tx_data),
	.tx_wr(tx_wr),
	
	.spi_done(spi_done),
	
	.cpol(CPOL),
	.cpha(CPHA)
);
 
// spi interface
wire csr_selected = (io_a == spdr_addr) | (io_a == spir_addr) | (io_a == spcr_addr)
				  | (io_a == spsr_addr);

assign tx_wr = io_we & (io_a == spdr_addr);
assign spsr_rd = io_re & (io_a == spsr_addr);

assign tx_data = io_di;


always @(posedge sys_clk, posedge sys_rst) begin
	if(sys_rst) begin // async reset
		io_do <= 8'd0;
		
		SPIE <= 1'b0;
		SPE  <= 1'b0;
		CPOL <= 1'b0;
		CPHA <= 1'b0;
		SPIF <= 1'b0;
		SPIR <= 4'd0;
		rx_data_reg <= 8'd0;
	end else begin
		io_do <= 8'd0;
		// status bit operation
		SPIF <= (spi_done & SPE) ? 1'b1 : ((spi_irq_ack | spsr_rd) ? 1'b0 : SPIF);

		if(spi_done)
			rx_data_reg <= rx_data;
		
		if(csr_selected) begin
			if(io_re) begin
				case(io_a) // io_do is registered.
					spdr_addr: io_do <= rx_data_reg; // SPDR
					spir_addr: io_do <= {4'd0, SPIR}; // SPIR
					spcr_addr: io_do <= {SPIE, SPE, 2'd0, CPOL, CPHA, 2'd0}; // SPCR
					spsr_addr: io_do <= {SPIF, 7'd0}; // SPSR
				endcase
			end
			if(io_we) begin
				case(io_a)
					spdr_addr: ; // handled by transceiver
					spir_addr: SPIR <= io_di[3:0];
					spcr_addr: begin
							SPIE <= io_di[7]; SPE <= io_di[6]; 
							CPOL <= io_di[3]; CPHA <= io_di[2];
						end
					spsr_addr: ; // SPSR (RO)
				endcase
			end
		end
	end
end

assign spi_irq = SPIE & SPIF;
 
 endmodule
 