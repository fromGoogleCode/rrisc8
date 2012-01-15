// Button debouncer inspired by MAX6816
// WangMengyin 2011-11-09
// ver1.0.0
`define DLY_40MS    19'd524288

module debouncer
(
    input wire clk, /* 10MHz */
    input wire rst,
    input wire button_in,
    output reg button_out
);

reg button_in_int;
reg [18:0] cnt;

always @(posedge clk)
begin
    if(rst)
    begin
        button_in_int <= button_in;
        button_out <= button_in;
        cnt <= 19'd0;
    end
    else if(button_in != button_in_int)
    begin
        button_in_int <= button_in;
        cnt <= 19'd0;
    end
    else if(cnt == `DLY_40MS)
        button_out <= button_in_int;
    else
        cnt <= cnt + 19'd1;
end

endmodule
