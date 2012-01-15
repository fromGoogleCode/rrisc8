/*
 * rAVR Prescaler
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
 
module prescaler #(
	parameter base_addr = 6'h10	// prescaler reg base 
	) (
 
	input wire sys_clk,
	input wire sys_rst,
	
	input wire [5:0] io_a,
	input wire io_we,
	input wire io_re,
	input wire [7:0] io_di,
	output reg [7:0] io_do,
	
	input wire [2:0] cs1, cs0,
	
	input wire t0, t1, // external clock input
	output reg clk_t1, clk_t0
);
 
wire csr_selected = io_a == base_addr;
 
reg psr10;
always @(posedge sys_clk, posedge sys_rst)
begin
	if(sys_rst)
		psr10 <= 1'b0;
	else if(csr_selected) begin
		if(io_we)
			psr10 <= io_di[0];
		if(io_re)
			io_do <= {7'd0, psr10};
    end
end


// sys clock divider
reg [9:0] count;
always @(posedge sys_clk)
begin
	if(sys_rst | psr10)
		count <= 10'd0;
	else
		count <= count + 10'd1;
end
 
wire t0_sync_fall, t0_sync_rise, t1_sync_fall, t1_sync_rise; // sync'd input clock
 
// timer external signal input sync
timer_sync t1_sync ( .sys_rst(sys_rst), .sys_clk(sys_clk), .t(t1), 
	.t_rise(t1_sync_rise), .t_fall(t1_sync_fall) );

timer_sync t0_sync ( .sys_rst(sys_rst), .sys_clk(sys_clk), .t(t0), 
	.t_rise(t0_sync_rise), .t_fall(t0_sync_fall) );
 
 // timer1 clk select
always @*
begin
	case (cs1)
		3'd0: clk_t1 = 1'b0;
		3'd1: clk_t1 = sys_clk;
		3'd2: clk_t1 = &count[2:0];  // clk/8
		3'd3: clk_t1 = &count[5:0];  // clk/64
		3'd4: clk_t1 = &count[7:0];  // clk/256
		3'd5: clk_t1 = &count[9:0];  // clk/1024
		3'd6: clk_t1 = t1_sync_fall; // external clk falling
		3'd7: clk_t1 = t1_sync_rise; // external clk rising
	endcase
end
 
 // timer0 clk select
always @*
begin
	case (cs0)
		3'd0: clk_t0 = 1'b0;
		3'd1: clk_t0 = sys_clk;
		3'd2: clk_t0 = &count[2:0];  // clk/8
		3'd3: clk_t0 = &count[5:0];  // clk/64
		3'd4: clk_t0 = &count[7:0];  // clk/256
		3'd5: clk_t0 = &count[9:0];  // clk/1024
		3'd6: clk_t0 = t0_sync_fall; // external clk falling
		3'd7: clk_t0 = t0_sync_rise; // external clk rising
	endcase
end
 
endmodule
 