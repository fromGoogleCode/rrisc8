/*
 * rAVR GPIO
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
 * 2011-11-16 Create Version 1.0.0
 * 2011-12-25 Revision 1.0.1
 */
 
module gpio #(
	parameter pin_addr = 6'h00,		// PINx reg
	parameter ddr_addr = 6'h01,		// DDRx reg
	parameter port_addr = 6'h02 	// PORTx reg
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
    input wire [7:0] pin_in,
    output reg [7:0] pin_out,
	output reg [7:0] pin_ddr
);

reg [7:0] pin_reg, pin_latch;

// synchronize input signal modified 2012-01-14
// avoid metastable state
always @(posedge sys_clk, posedge sys_rst)
begin
    if(sys_rst)
        pin_latch <= 1'b0;
	else if(sys_clk)
		pin_latch <= pin_in;
end

wire csr_selected = (io_a == pin_addr) | (io_a == ddr_addr) | (io_a == port_addr);

always @(posedge sys_clk, posedge sys_rst)
begin
    if(sys_rst) begin
        pin_reg     <= 8'h00;
        pin_out    	<= 8'h00;
        pin_ddr    	<= 8'h00;
		io_do		<= 8'h00;
    end else begin
        pin_reg = pin_latch;
		if(csr_selected)
			if(io_we) // IO Write
				case(io_a)
					ddr_addr 	: pin_ddr  <= io_di; // DDRx
					port_addr  	: pin_out  <= io_di; // PORTx
					default     : ;
				endcase
			if(io_re) // IO Read
				case(io_a)
					pin_addr	: io_do	   <= pin_reg; // PINx
					ddr_addr	: io_do    <= pin_ddr; // DDRx
					port_addr	: io_do    <= pin_out; // PORTx
					default		: io_do    <= 8'h00;
				endcase
			else
				io_do <= 8'h00;
    end
end

endmodule
