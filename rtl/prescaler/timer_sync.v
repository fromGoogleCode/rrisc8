/*
 * rAVR Prescaler external clock sync
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
 
`define TIME_SYNC_LATCH 
 
 module timer_sync (
	input wire sys_rst,
	input wire sys_clk,
 
	input wire t, // external input clock
	output wire t_rise,
	output wire t_fall
 );

// Latch
`ifdef TIME_SYNC_LATCH
reg t_latch;
always @(sys_clk, t)
begin
	if(sys_clk)	t_latch <= t;
end
`endif

reg t_reg;
always @(posedge sys_clk)
begin
	if(sys_rst)
		t_reg <= 1'b0;
	else
`ifdef TIME_SYNC_LATCH
		t_reg <= t_latch;
`else
		t_reg <= t;
`endif
end

// edge detect
reg t_reg2;
always @(posedge sys_clk)
begin
	if(sys_rst)
		t_reg2 <= 1'b0;
	else
		t_reg2 <= t_reg;
end

assign t_rise = ~t_reg2 & t_reg;
assign t_fall = t_reg2 & ~t_reg;
 
endmodule
 