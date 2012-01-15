/*
 * rAVR TIMER8
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
 // 2012-01-01 modified ov generation logic
 
 
 /* Timer8 module emulate AT90S2313's 8-bit timer, but specified register define is sightly different.
  * It can be used in RTOS Systick timer.
  * REG define & address
  * TCN0		(01_0000) |d7 d6 d5 d4 d3 d2 d1 d0|	(RW) timer8 count register
  * TCCR0		(01_0001) |x x x x x r2 r1 r0| (RW) timer8 clock divider register
  * TIMSK		(01_0010) |TOIE0 x x x x x x x| (RW) timer8 interrupt mask register,share with timer16
  * TIFR		(01_0011) |TOV0 x x x x x x x| (RW) timer8 overflow flag register,share with timer16
  * Note: TOV0 can be cleared automatically when entering Interrupt service by processor
  * 	  or program write '1' to TOV0 bit will clear TOV0.
  *
  */
  
module timer0 #(
	parameter base_addr = 6'h11 	   // TIMER8 I/O address = 0'b01_00xx
) (
  	input wire sys_clk,
	input wire sys_rst,
	
	input wire [5:0] io_a,
	input wire io_we,
	input wire io_re,
	input wire [7:0] io_di,
	output reg [7:0] io_do,
	
	input wire timer_clk, // from prescaler
	output wire [2:0] timer_clk_sel,
	
	output wire timer_ov_irq,
	input wire timer_ov_irq_ack
);

localparam tcn0_addr 	= base_addr;
localparam tccr0_addr 	= base_addr + 6'd1;
localparam timsk0_addr 	= base_addr + 6'd2;
localparam tifr0_addr 	= base_addr + 6'd3;
  
reg [2:0] CS0; // clock select REG
reg TOIE0;	   // timer overflow interrupt enable
reg TOV0;

assign timer_clk_sel = CS0;

// timer8 interface
wire csr_selected = (io_a == tcn0_addr) | (io_a == tccr0_addr) |
				   (io_a == timsk0_addr) | (io_a == tifr0_addr);
 
wire count8_wr = csr_selected & io_we & ( io_a == tcn0_addr );
wire tov0_wr = csr_selected & io_we & ( io_a == tifr0_addr) & io_di[7];

wire ov, cnt_equ; // modified 2012-01-01
reg cnt_equ_reg; // added 2012-01-01
reg [7:0] count8;

always @(posedge sys_clk)
begin
	if(sys_rst)
		count8 <= 8'd0;
	else if(count8_wr)
		count8 <= io_di;
	else if(timer_clk)
		count8 <= count8 + 8'd1;
end

assign cnt_equ = count8 == 8'hFF;
always @(posedge sys_clk, posedge sys_rst)
begin
	if(sys_rst)
		cnt_equ_reg <= 1'b0;
	else
		cnt_equ_reg <= cnt_equ;
end
assign ov = cnt_equ & ~cnt_equ_reg; // added 2012-01-01

// read and write process
always @(posedge sys_clk, posedge sys_rst) begin
	if(sys_rst) begin
		io_do <= 8'd0;
		
		CS0 <= 3'd0;	// defualt disable timer clock
		TOIE0 <= 1'b0;
		TOV0 <= 1'b0;
	end else begin
		io_do <= 8'd0;
		
		// clear TOV0 bit condiction: interrupt handler automatically clear OR write 1 to this bit.
		TOV0 <= ov ? 1'b1 : ((timer_ov_irq_ack | tov0_wr) ? 1'b0 : TOV0);
		
		if(csr_selected) begin
			if(io_re) begin
				case(io_a)
					tcn0_addr: 		io_do <= count8;		// TCN0
					tccr0_addr: 	io_do <= {5'd0, CS0};	// TCCR0
					timsk0_addr: 	io_do <= {TOIE0, 7'd0};	// TIMSK0
					tifr0_addr: 	io_do <= {TOV0, 7'd0};	// TIFR0
				endcase
			end
			if(io_we) begin
				case(io_a)
					tcn0_addr: ;
					tccr0_addr: 	CS0   <= io_di[2:0];		// TCCR0
					timsk0_addr: 	TOIE0 <= io_di[7];		// TIMSK0
					tifr0_addr: ;
				endcase
			end
		end
	end
end

assign timer_ov_irq = TOIE0 & TOV0;
  
endmodule
  