/*
 * Top entity of rRISC8
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
 * 2011-11-16 Create Version 1.0.0
 *      (1) Create basic "navre" core.
 * 2011-12-25 Revision 1.0.1
 *      (1) Add all Peripheral supported by DE0-Nano board.
 */

module rRISC8
(
    // system clock & reset
    input  wire          clk_50MHz_pad_i,    // 50MHz cyrstal osc input     PIN_R8
    input  wire          n_rst_pad_i,        // sync Reset (KEY[0])         PIN_J15
    // GPIO IN/OUT
    input  wire          n_button_pad_i,     // test Button (KEY[1])        PIN_E1
    output wire[7:0]     led_pad_o,          // test LED (LED[7..0])              refer to user manual page.14
    input  wire[3:0]     dip_switch_pad_i,   // test Switch key input (KEY[3..0]) refer to user manual page.14
    // I2C EEPROM & Accelerometer
    inout  wire          i2c_sclk_pad_io,     // I2C clock       PIN_F2
    inout  wire          i2c_sdat_pad_io,    // I2C data        PIN_F1
    // SPI A/D Converter
    output wire          spi_ncs_pad_o,      // SPI cs          PIN_A10
    input  wire          spi_din_pad_i,      // SPI data in     PIN_B10
    output wire          spi_dout_pad_o,     // SPI data out    PIN_A9
    output wire          spi_sclk_pad_o,     // SPI clock out   PIN_B14
    // UART
    output wire          uart_txd_pad_o,     // UART tx
    input  wire          uart_rxd_pad_i,      // UART rx
    
    // following pad is for test purpose only.
    output wire          test_spi_ncs_o,     // monitor nCS signal
    output wire          test_spi_din_o,     // monitor DIN signal
    output wire          test_spi_dout_o,    // monitor DOUT signal
    output wire          test_spi_sclk_o,    // monitor SCLK signal
	
	output wire			 test_i2c_sclk_o,	 // monitor SCLK signal
	output wire 		 test_i2c_sdat_o	 // monitor SDAT signal
);

wire rst; // internal reset signal
wire clk; // 10MHz main clock
//
wire [10:0] pmem_a;
wire [15:0] pmem_d;
wire pmem_ce;
//
wire [9:0] dmem_a;
wire [7:0] dmem_do, dmem_di;
wire dmem_we;
//
wire io_re, io_we;
wire [5:0] io_a;
wire [7:0] io_do, io_di;

wire[10:1] int_line;
wire irq_ack; // 12-29
wire[3:0] irq_ack_ad; // 12-29

// rst gen
rst_gen rst_gen_inst (
    .nrst_i(n_rst_pad_i),
    .rst_o(rst),
    
    .clk(clk)
 );

// 10MHz system clk PLL 
clkgen	clkgen_inst (
	.inclk0 ( clk_50MHz_pad_i ),
	.c0 ( clk )
	);

// Instance of navre light-weight RSIC8 core
navre #(
	.pmem_width(11), /* 4KByte 16-bit Program ROM */
	.dmem_width(10)  /* 1KByte  8-bit Data RAM, actually use low 767 bytes */
) cpu_inst (
	.clk(clk),
	.rst(rst),

	.pmem_ce(pmem_ce),
	.pmem_a(pmem_a),
	.pmem_d(pmem_d),

	.dmem_we(dmem_we),
	.dmem_a(dmem_a),
	.dmem_di(dmem_do),
	.dmem_do(dmem_di),

	.io_re(io_re),
	.io_we(io_we),
	.io_a(io_a), /* modified 11-03 */
	.io_do(io_di), /* modified 11-03 */
	.io_di(io_do),
    
    .irqlines(int_line), /* interrupt input */
    .irqack(irq_ack),
    .irqackad(irq_ack_ad)
);

// 4KB PROM
prom	prom_inst (
	.address ( pmem_a ),
	.clken ( pmem_ce ),
	.clock ( clk ),
	.q ( pmem_d )
	);

// 1KB DRAM
dram	dram_inst (
	.address ( dmem_a ),
	.clock ( clk ),
	.data ( dmem_di ), // data written to data ram
	.wren ( dmem_we ),
	.q ( dmem_do ) // data read from ram
	);

// PORTA dip button(KEY[1] & switch(KEY[3..0]))
wire [7:0] porta_do;

gpio #(
	.pin_addr(6'h00),
	.ddr_addr(6'h01),
	.port_addr(6'h02)
) porta_inst
(
	.sys_clk(clk),
    .sys_rst(rst),
    .io_a(io_a),
    .io_di(io_di),
    .io_do(porta_do),
    .io_re(io_re),
    .io_we(io_we),

    .pin_in({3'b000, n_button_pad_i, dip_switch_pad_i}),
    .pin_out(),
	.pin_ddr()
);

// PORTB LED
wire [7:0] portb_do;

gpio #(
	.pin_addr(6'h03),
	.ddr_addr(6'h04),
	.port_addr(6'h05)
) portb_inst
(
	.sys_clk(clk),
    .sys_rst(rst),
    .io_a(io_a),
    .io_di(io_di),
    .io_do(portb_do),
    .io_re(io_re),
    .io_we(io_we),

    .pin_in(),
    .pin_out(led_pad_o),
	.pin_ddr()
);

// PORTC GPIO
wire [7:0] portc_do;
wire [7:0] portc_out_int;

gpio #(
	.pin_addr(6'h06),
	.ddr_addr(6'h07),
	.port_addr(6'h08)
) portc_inst
(
	.sys_clk(clk),
    .sys_rst(rst),
    .io_a(io_a),
    .io_di(io_di),
    .io_do(portc_do),
    .io_re(io_re),
    .io_we(io_we),

    .pin_in(),
    .pin_out(portc_out_int),
	.pin_ddr()
);

assign spi_ncs_pad_o = portc_out_int[0]; // wired to spi nCS pin

// UART
wire [7:0] uart_do;
wire uart_txc_irq, uart_rxc_irq, uart_udr_irq;
wire uart_txc_irq_ack = (irq_ack_ad == 4'd9) & irq_ack; // 12-29

uart #(
	.base_addr(6'h0c),
	.clk_freq(10000000),
	.baud(9600)
) uart_inst
(
	.sys_clk(clk),
	.sys_rst(rst),
	
	.io_a(io_a),
	.io_we(io_we),
	.io_re(io_re),
	.io_di(io_di),
	.io_do(uart_do),

	.rxc_irq(uart_rxc_irq),
	.txc_irq(uart_txc_irq),
	.udr_irq(uart_udr_irq),
	.txc_irq_ack(uart_txc_irq_ack),

	.uart_rx(uart_rxd_pad_i),
	.uart_tx(uart_txd_pad_o)

);


// timer prescaler
wire timer0_clk;
wire [2:0] timer0_cs;
wire [7:0] prescaler_do;

prescaler #(
	.base_addr(6'h10)
) perscaler_inst
    (
	.sys_clk(clk),
	.sys_rst(rst),
	
	.io_a(io_a),
	.io_we(io_we),
	.io_re(io_re),
	.io_di(io_di),
	.io_do(prescaler_do),
	
	.cs1(),
    .cs0(timer0_cs),
	.t0(),
    .t1(),
    
	.clk_t1(),
    .clk_t0(timer0_clk)
);

// timer0
wire timer0_ov_irq;
wire timer0_ov_irq_ack = (irq_ack_ad == 4'd6) & irq_ack;
wire [7:0] timer0_do;

timer0 #(
	.base_addr(6'h11)
) timer0_inst (
  	.sys_clk(clk),
	.sys_rst(rst),
	
	.io_a(io_a),
	.io_we(io_we),
	.io_re(io_re),
	.io_di(io_di),
	.io_do(timer0_do),
	
	.timer_clk(timer0_clk),
	.timer_clk_sel(timer0_cs),
	
	.timer_ov_irq(timer0_ov_irq),
	.timer_ov_irq_ack(timer0_ov_irq_ack)
);

// spi
wire spi_irq;
wire spi_irq_ack = (irq_ack_ad == 4'd10) & irq_ack;
wire [7:0] spi_do;

spi #(
	.base_addr(6'h15)
) spi_inst(
	.sys_clk(clk),
	.sys_rst(rst),
	
	.io_a(io_a),
	.io_we(io_we),
	.io_re(io_re),
	.io_di(io_di),
	.io_do(spi_do),

	.spi_irq(spi_irq),
	.spi_irq_ack(spi_irq_ack),

	.spi_miso(spi_din_pad_i),
	.spi_mosi(spi_dout_pad_o),
	.spi_sck(spi_sclk_pad_o)
);

// test purpose only
assign test_spi_din_o   = spi_din_pad_i;
assign test_spi_dout_o  = spi_dout_pad_o;
assign test_spi_sclk_o  = spi_sclk_pad_o;
assign test_spi_ncs_o   = spi_ncs_pad_o;

// i2c master
wire [7:0] i2c_do;
wire i2c_irq;

wire scl_o, sda_o, scl_i, sda_i, scl_oen_oe, sda_oen_oe;

assign i2c_sclk_pad_io = scl_oen_oe ? 1'bz : scl_o;
assign i2c_sdat_pad_io = sda_oen_oe ? 1'bz : sda_o;
assign scl_i = i2c_sclk_pad_io; 
assign sda_i = i2c_sdat_pad_io; 

// test purpose only
assign test_i2c_sclk_o = i2c_sclk_pad_io;
assign test_i2c_sdat_o = i2c_sdat_pad_io;

i2c_master #(
	.base_addr(6'h19)
) i2c_master_inst (
	.sys_clk(clk),
    .sys_rst(rst),

    .io_a(io_a),
    .io_di(io_di),
    .io_do(i2c_do),
    .io_re(io_re),
    .io_we(io_we),

	.i2c_irq(i2c_irq),

	.scl_i(scl_i),	   
	.scl_o(scl_o),	   
	.scl_oen_o(scl_oen_oe), 
	.sda_i(sda_i),
	.sda_o(sda_o),
	.sda_oen_o(sda_oen_oe)
);

// CSR bus
assign io_do = porta_do | portb_do | uart_do | prescaler_do | timer0_do
             | spi_do | portc_do | i2c_do;

// CPU interrupt line
assign int_line = {spi_irq, uart_txc_irq, uart_udr_irq, uart_rxc_irq, 
                   timer0_ov_irq, i2c_irq, 4'd0};

endmodule
