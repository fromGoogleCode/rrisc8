/*
 * rRISC I2C Master
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
 /* Change History:
 * 2012-01-04 Create Version 1.0.0
 */

`include "timescale.v"

`include "i2c_master_defines.v"

module i2c_master #(
	parameter base_addr = 6'h19
)
(
	//
    input wire sys_clk,
    input wire sys_rst,
    //
    input wire [5:0] io_a,
    input wire [7:0] io_di,
    output reg [7:0] io_do,
    input wire io_re,
    input wire io_we,
    //
	output reg i2c_irq,
	//
	input wire scl_i,	   // SCL-line input
	output wire scl_o,	   // SCL-line output (always 1'b0)
	output wire scl_oen_o, // SCL-line output enable (active low)
	input wire sda_i,      // SDA-line input
	output wire sda_o,	   // SDA-line output (always 1'b0)
	output wire sda_oen_o  // SDA-line output enable (active low)
);

    // register address	
	localparam prer_low_addr 	= base_addr;
	localparam prer_high_addr 	= base_addr + 6'd1;
	localparam ctr_addr  		= base_addr + 6'd2;
	localparam txr_addr  		= base_addr + 6'd3;
	localparam rxr_addr  		= base_addr + 6'd4;
	localparam cr_addr  			= base_addr + 6'd5;
	localparam sr_addr  			= base_addr + 6'd6;
	
	wire csr_selected = (io_a == prer_low_addr) | (io_a == prer_high_addr) |
						(io_a == ctr_addr) | (io_a == rxr_addr) |
						(io_a == sr_addr) | (io_a == txr_addr) |
						(io_a == cr_addr);
	
	//
	// variable declarations
	//

	// registers
	reg  [15:0] prer; // clock prescale register
	reg  [ 7:0] ctr;  // control register
	reg  [ 7:0] txr;  // transmit register
	wire [ 7:0] rxr;  // receive register
	reg  [ 7:0] cr;   // command register
	wire [ 7:0] sr;   // status register

	// done signal: command completed, clear command register
	wire done;

	// core enable signal
	wire core_en;
	wire ien;

	// status register signals
	wire irxack;
	reg  rxack;       // received aknowledge from slave
	reg  tip;         // transfer in progress
	reg  irq_flag;    // interrupt pending flag
	wire i2c_busy;    // bus busy (start signal detected)
	wire i2c_al;      // i2c bus arbitration lost
	reg  al;          // status register arbitration lost bit

	//
	// module body
	//

	// assign io_do
	always @(posedge sys_clk)
	begin
	  io_do <= 8'd00;
	  if(io_re & csr_selected)
		case (io_a)
			prer_low_addr: 		io_do <= #1 prer[ 7:0];
			prer_high_addr: 	io_do <= #1 prer[15:8];
			ctr_addr: 			io_do <= #1 ctr;
			rxr_addr: 			io_do <= #1 rxr;
			sr_addr: 			io_do <= #1 sr;
			txr_addr: 			io_do <= #1 txr;
			cr_addr: 			io_do <= #1 cr;
			default: 			;   			 // reserved
		endcase
	end

	// generate registers
	always @(posedge sys_clk or posedge sys_rst)
	  if (sys_rst)
	    begin
	        prer <= #1 16'hffff;
	        ctr  <= #1  8'h0;
	        txr  <= #1  8'h0;
	    end
	  else
	    if (io_we & csr_selected)
	      case (io_a)
	         prer_low_addr : 	prer [ 7:0] <= #1 io_di;
	         prer_high_addr : 	prer [15:8] <= #1 io_di;
	         ctr_addr : 				ctr <= #1 io_di;
	         txr_addr : 				txr <= #1 io_di;
	         default: ;
	      endcase

	// generate command register (special case)
	always @(posedge sys_clk or posedge sys_rst)
	  if (sys_rst)
	    cr <= #1 8'h0;
	  else if (io_we & (io_a == cr_addr))
	    begin
	        if (core_en)
	          cr <= #1 io_di;
	    end
	  else
	    begin
	        if (done | i2c_al)
	          cr[7:4] <= #1 4'h0;           // clear command bits when done
	                                        // or when aribitration lost
	        cr[2:1] <= #1 2'b0;             // reserved bits
	        cr[0]   <= #1 1'b0;             // clear IRQ_ACK bit
	    end


	// decode command register
	wire sta  = cr[7];
	wire sto  = cr[6];
	wire rd   = cr[5];
	wire wr   = cr[4];
	wire ack  = cr[3];
	wire iack = cr[0];

	// decode control register
	assign core_en = ctr[7];
	assign ien = ctr[6];

	// hookup byte controller block
	i2c_master_byte_ctrl byte_controller (
		.clk      ( sys_clk     ),
		.rst      ( sys_rst     ),
		.ena      ( core_en      ),
		.clk_cnt  ( prer         ),
		.start    ( sta          ),
		.stop     ( sto          ),
		.read     ( rd           ),
		.write    ( wr           ),
		.ack_in   ( ack          ),
		.din      ( txr          ),
		.cmd_ack  ( done         ),
		.ack_out  ( irxack       ),
		.dout     ( rxr          ),
		.i2c_busy ( i2c_busy     ),
		.i2c_al   ( i2c_al       ),
		.scl_i    ( scl_i    ),
		.scl_o    ( scl_o    ),
		.scl_oen  ( scl_oen_o ),
		.sda_i    ( sda_i    ),
		.sda_o    ( sda_o    ),
		.sda_oen  ( sda_oen_o )
	);

	// status register block + interrupt request signal
	always @(posedge sys_clk or posedge sys_rst)
	  if (sys_rst)
	    begin
	        al       <= #1 1'b0;
	        rxack    <= #1 1'b0;
	        tip      <= #1 1'b0;
	        irq_flag <= #1 1'b0;
	    end
	  else
	    begin
	        al       <= #1 i2c_al | (al & ~sta);
	        rxack    <= #1 irxack;
	        tip      <= #1 (rd | wr);
	        irq_flag <= #1 (done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
	    end

	// generate interrupt request signals
	always @(posedge sys_clk or posedge sys_rst)
	  if (sys_rst)
	    i2c_irq <= #1 1'b0;
	  else
	    i2c_irq <= #1 irq_flag && ien; // interrupt signal is only generated when IEN (interrupt enable bit is set)

	// assign status register bits
	assign sr[7]   = rxack;
	assign sr[6]   = i2c_busy;
	assign sr[5]   = al;
	assign sr[4:2] = 3'h0; // reserved
	assign sr[1]   = tip;
	assign sr[0]   = irq_flag;

endmodule
