/*
 * rAVR SPI transceiver
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
 
 module spi_transceiver(
	input wire sys_rst,
	input wire sys_clk,
	
	input wire spi_miso,
	output wire spi_mosi,
	output reg spi_sck,
	
	input wire [3:0] divisor,
	
	input wire spi_enable,
	
	output wire [7:0] rx_data,

	input wire [7:0] tx_data,
	input wire tx_wr,
	
	output reg spi_done,
	
	input wire cpol,
	input wire cpha
 );
 
localparam IDLE = 2'b00;
localparam CP2  = 2'b01;
localparam CP1  = 2'b10;

reg [1:0] state;
reg ena;
reg [11:0] count;

// ena signal generation, sck clock divider 
always @(posedge sys_clk, posedge sys_rst) begin
	if(sys_rst)
		count <= 12'd1;
	else if(spi_enable && (state != IDLE) && (count != 12'b0))
		count <= count - 12'h1;
	else
		case(divisor) // reload counter
			4'h0: count <= 12'd1; 		// div = 2;
			4'h1: count <= 12'd3; 		// div = 4;
			4'h2: count <= 12'd7; 		// div = 8;
			4'h3: count <= 12'd7; 		// div = 16;
			4'h4: count <= 12'd15; 		// div = 32;
			4'h5: count <= 12'd63; 		// div = 64;
			4'h6: count <= 12'd127; 	// div = 128;
			4'h7: count <= 12'd255; 	// div = 256;
			4'h8: count <= 12'd511; 	// div = 512;
			4'h9: count <= 12'd1023; 	// div = 1024;
			4'hA: count <= 12'd2047; 	// div = 2048;
			4'hB: count <= 12'd4095; 	// div = 4096;
			default: count <= 12'd1; 	// div = 2;
		endcase;
end

wire sclk_ena = ~|count; // sck enable signal

reg [2:0] bcnt;
reg [7:0] data_reg;

// transfer state machine
always @(posedge sys_clk, posedge sys_rst) begin
	if(sys_rst) begin
		state <= IDLE;
		bcnt <= 3'd0;
		data_reg <= 8'd0;
		spi_sck <= 1'b0;
	end
	else if(~spi_enable) begin
		state <= IDLE;
		bcnt <= 3'd0;
		data_reg <= 8'd0;
		spi_sck <= 1'b0;
	end
	else begin
		spi_done <= 1'b0;
		
		case(state)
			IDLE: begin
				bcnt <= 3'd7;
				if(~tx_wr) begin
					data_reg <= 8'd0;
					spi_sck <= cpol; // set clock polarity
				end else begin // start transfer
					state <= CP2;
					data_reg <= tx_data; // load tx data
					if(cpha) spi_sck <= ~spi_sck; // set clock phase, cpha = 1, add an extra edge change
				end
			end
			CP2: begin // clock phase 2, next data
				if(sclk_ena) begin
					spi_sck <= ~spi_sck;
					state <= CP1;
				end
			end
			CP1: begin
				if(sclk_ena) begin
					data_reg <= {data_reg[6:0], spi_miso}; // sample MISO
					bcnt <= bcnt - 3'd1;

					if(~|bcnt) begin // bcnt = 3'b000;
						state <= IDLE;
						spi_sck <= cpol;
						spi_done <= 1'b1;
					end else begin
						state <= CP2;
						spi_sck <= ~spi_sck;
					end
				end
			end
			default: state <= IDLE; // invaild state
		endcase;
	end
end

assign spi_mosi = data_reg[7];
assign rx_data = data_reg;

endmodule

