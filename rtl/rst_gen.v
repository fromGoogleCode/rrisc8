/*
 * Reset logic for rRISC
 * Copyright (C) 2011 WangMengyin tigerwang202@gmail.com
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
 * 2012-01-09 Create Version 1.0.0
 *
 */
 
 /*
  * Reset bridge circuit asserts asynchronously
  * and deasserts synchronously.
  * refer to article "How do I reset my FPGA?" in EETIMES.com
  */
 
module rst_gen (
    input wire nrst_i,
    output wire rst_o,
    
    input wire clk
 );
 
reg rst1_reg, rst2_reg;
assign rst_o = rst2_reg;
 
always@(posedge clk, negedge nrst_i)
begin
    if(!nrst_i) begin
        rst1_reg <= 1'b1;
        rst2_reg <= 1'b1;
    end else begin
        rst1_reg <= 1'b0;
        rst2_reg <= rst1_reg;
    end
end
 
endmodule
 