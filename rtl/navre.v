/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * Modified by WangMengyin 2011
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


module navre #(
	parameter pmem_width = 11, /* < in 16-bit instructions */
	parameter dmem_width = 13  /* < in bytes */
) (
	input clk,
	input rst,

	output reg pmem_ce,
	output [pmem_width-1:0] pmem_a,
	input [15:0] pmem_d,

	output reg dmem_we,
	output wire [dmem_width-1:0] dmem_a,
	input [7:0] dmem_di,
	output wire [7:0] dmem_do,

	output reg io_re,
	output reg io_we,
	output reg [5:0] io_a, /* modified 11-03 */
	output reg [7:0] io_do, /* modified 11-03 */
	input [7:0] io_di,
    
    input wire [9:0] irqlines, /* AT90S2313's interrupt line, add 11-09 */
    output reg irqack, /* add 11-07 */
    output reg [3:0] irqackad /* add 11-07 */
);

/* Register file */
reg [pmem_width-1:0] PC;
reg [7:0] GPR[0:23];
reg [15:0] U;	/* < R24-R25 */
reg [15:0] pX;	/* < R26-R27 */
reg [15:0] pY;	/* < R28-R29 */
reg [15:0] pZ;	/* < R30-R31 */
reg I, T, H, S, V, N, Z, C;

/* Stack */
reg [7:0] io_sp; // sp in 8-bit
reg [15:0] SP;
reg push;
reg pop;
always @(posedge clk) begin
	if(rst) begin
		io_sp <= 8'd0;
		SP <= 16'd0;
	end else begin
		io_sp <= io_a[0] ? SP[7:0] : SP[15:8]; // read SP
		if((io_a == 6'b111101) | (io_a == 6'b111110)) begin // write SP
			if(io_we) begin
				if(io_a[0])
					SP[7:0] <= io_do;
				else
					SP[15:8] <= io_do;
			end
		end
		if(push)
			SP <= SP - 16'd1;
		if(pop)
			SP <= SP + 16'd1;
	end
end

/* I/O mapped registers */

localparam IO_SEL_EXT	= 2'd0;
localparam IO_SEL_STACK	= 2'd1;
localparam IO_SEL_SREG	= 2'd2;

reg [1:0] io_sel;
always @(posedge clk) begin
	if(rst)
		io_sel <= IO_SEL_EXT;
	else begin
		case(io_a)
			6'b111101,
			6'b111110: io_sel <= IO_SEL_STACK;
			6'b111111: io_sel <= IO_SEL_SREG;
			default: io_sel <= IO_SEL_EXT;
		endcase
	end
end

/* Register operations */
wire immediate = (pmem_d[14]
	| (pmem_d[15:12] == 4'b0011))		/* CPI */
	& (pmem_d[15:10] != 6'b111111)		/* SBRC - SBRS */
	& (pmem_d[15:10] != 6'b111110);		/* BST - BLD */
reg lpm_en;
wire [4:0] Rd = lpm_en ? 5'd0 : {immediate | pmem_d[8], pmem_d[7:4]};
wire [4:0] Rr = {pmem_d[9], pmem_d[3:0]};
wire [7:0] K = {pmem_d[11:8], pmem_d[3:0]};
wire [2:0] b = pmem_d[2:0];
wire [11:0] Kl = pmem_d[11:0];
wire [6:0] Ks = pmem_d[9:3];
wire [1:0] Rd16 = pmem_d[5:4];
wire [5:0] K16 = {pmem_d[7:6], pmem_d[3:0]};
wire [5:0] q = {pmem_d[13], pmem_d[11:10], pmem_d[2:0]};

wire [7:0] GPR_Rd8 = GPR[Rd];
wire [7:0] GPR_Rr8 = GPR[Rr];
reg [7:0] GPR_Rd;
always @(*) begin
	case(Rd)
		default: GPR_Rd = GPR_Rd8;
		5'd24: GPR_Rd = U[7:0];
		5'd25: GPR_Rd = U[15:8];
		5'd26: GPR_Rd = pX[7:0];
		5'd27: GPR_Rd = pX[15:8];
		5'd28: GPR_Rd = pY[7:0];
		5'd29: GPR_Rd = pY[15:8];
		5'd30: GPR_Rd = pZ[7:0];
		5'd31: GPR_Rd = pZ[15:8];
	endcase
end
reg [7:0] GPR_Rr;
always @(*) begin
	case(Rr)
		default: GPR_Rr = GPR_Rr8;
		5'd24: GPR_Rr = U[7:0];
		5'd25: GPR_Rr = U[15:8];
		5'd26: GPR_Rr = pX[7:0];
		5'd27: GPR_Rr = pX[15:8];
		5'd28: GPR_Rr = pY[7:0];
		5'd29: GPR_Rr = pY[15:8];
		5'd30: GPR_Rr = pZ[7:0];
		5'd31: GPR_Rr = pZ[15:8];
	endcase
end
wire GPR_Rd_b = GPR_Rd[b];

reg [15:0] GPR_Rd16;
always @(*) begin
	case(Rd16)
		2'd0: GPR_Rd16 = U;
		2'd1: GPR_Rd16 = pX;
		2'd2: GPR_Rd16 = pY;
		2'd3: GPR_Rd16 = pZ;
	endcase
end

/* Memorize values to support 16-bit instructions */
reg regmem_ce;

reg [4:0] Rd_r;
reg [7:0] GPR_Rd_r;
always @(posedge clk) begin
	if(regmem_ce)
		Rd_r <= Rd; /* < control with regmem_ce */
	GPR_Rd_r <= GPR_Rd; /* < always loaded */
end

/* PC */

reg [3:0] pc_sel;

localparam PC_SEL_NOP		= 4'd0;
localparam PC_SEL_INC		= 4'd1;
localparam PC_SEL_KL		= 4'd2;
localparam PC_SEL_KS		= 4'd3;
localparam PC_SEL_DMEML		= 4'd4;
localparam PC_SEL_DMEMH		= 4'd6;
localparam PC_SEL_DEC		= 4'd7;
localparam PC_SEL_Z		    = 4'd8;
localparam PC_SEL_IRQ       = 4'd9; /* add 11-09 */

/* SRAM space address generate & Data path select */
/* AVR core map REG, I/O, DMEM to a single linear space. */
reg [7:0] dmem_di_int; /* internal sram data input */
reg [7:0] dmem_do_int; /* internal sram data output */
reg [15:0] dmem_a_int; /* internal sram address (64KB SRAM address)*/

localparam DMEM_A_SEL_REG   = 2'd0;
localparam DMEM_A_SEL_IO    = 2'd1;
localparam DMEM_A_SEL_SRAM  = 2'd2;
reg [1:0] dmem_a_sel;

always @*
begin
    casex(dmem_a_int)
        16'b0000_0000_000x_xxxx: dmem_a_sel = DMEM_A_SEL_REG;
        16'b0000_0000_001x_xxxx,
        16'b0000_0000_010x_xxxx: dmem_a_sel = DMEM_A_SEL_IO;
        default: dmem_a_sel = DMEM_A_SEL_SRAM;
    endcase
end

/* dmem address remap 2011-11-05 */
wire [4:0] dmem_a_int_reg = dmem_a_int[4:0]; /* address for GPREG */

wire [15:0] dmem_a_offset_32 = dmem_a_int - 16'h0020; /* generate I/O address */ //fix a bug
wire [5:0] dmem_a_int_io  = dmem_a_offset_32[5:0]; /* address for I/O 0x00 ~0x3F */

wire [15:0] dmem_a_offset_96 = dmem_a_int - 16'h0060; /* generate DMEM address */
assign dmem_a = dmem_a_offset_96[dmem_width-1:0]; /* wire to external dmem address line */

/* dmem data in select */
reg [1:0] dmem_a_sel_reg;
always @(posedge clk)
begin
    dmem_a_sel_reg <= dmem_a_sel; // Delay 1 clk, for POP LD LDS instruction
    // these instructions takes 2 clk, address is vaild in fisrt clk cycle. 11-07
    // For LDS, address is vaild in second clk, 
end

always @*
begin
    dmem_di_int = 8'h00;
    case(dmem_a_sel_reg)
        DMEM_A_SEL_REG:
        begin
        case(dmem_a_int_reg) // read REG
            default: dmem_di_int = GPR[dmem_a_int_reg];
            5'd24: dmem_di_int = U[7:0];
            5'd25: dmem_di_int = U[15:8];
            5'd26: dmem_di_int = pX[7:0];
            5'd27: dmem_di_int = pX[15:8];
            5'd28: dmem_di_int = pY[7:0];
            5'd29: dmem_di_int = pY[15:8];
            5'd30: dmem_di_int = pZ[7:0];
            5'd31: dmem_di_int = pZ[15:8];
        endcase
        end
        DMEM_A_SEL_IO:
        begin   // read I/O space
        case(dmem_a_int_io)
            default: dmem_di_int = io_di; // EXT
            6'b111101,
			6'b111110: dmem_di_int = io_sp; // SP
            6'b111111: dmem_di_int = {I, T, H, S, V, N, Z, C}; // SREG // modified 11-07
        endcase
        end
        DMEM_A_SEL_SRAM:
        begin
            dmem_di_int = dmem_di;
        end
        default: ;
    endcase
end

/* dmem data out */
assign dmem_do = dmem_a_sel == DMEM_A_SEL_SRAM ? dmem_do_int : 8'hxx; /* output to external sram */

// added 11-05

always @(posedge clk) begin
	if(rst) begin
		PC <= 0;
	end else begin
		case(pc_sel)
			PC_SEL_NOP:;
			PC_SEL_INC: PC <= PC + 1'b1;
			// !!! WARNING !!! replace with PC <= PC + {{pmem_width-12{Kl[11]}}, Kl}; if pmem_width>12
			PC_SEL_KL: PC <= PC + Kl;
			PC_SEL_KS: PC <= PC + {{pmem_width-7{Ks[6]}}, Ks};
			PC_SEL_DMEML: PC[7:0] <= dmem_di; /* get low 8-bit PC for RET RETI instruction */
			PC_SEL_DMEMH: PC[pmem_width-1:8] <= dmem_di; /* get high 8-bit PC for RET RETI instruction */
			PC_SEL_DEC: PC <= PC - {{pmem_width-1{1'b0}}, 1'b1};
			PC_SEL_Z: PC <= pZ - 1'b1;
            PC_SEL_IRQ: PC <= {{pmem_width-4{1'b0}}, irqackad}; /* interrupt vector */
		endcase
	end
end
reg pmem_selz;
assign pmem_a = rst ? 0 : (pmem_selz ? pZ[15:1] : PC + {{pmem_width-1{1'b0}}, 1'b1});

/* Load/store operations */
reg [3:0] dmem_sel;

localparam DMEM_SEL_UNDEFINED	= 3'bxxx;
localparam DMEM_SEL_X		= 4'd0;
localparam DMEM_SEL_XPLUS	= 4'd1;
localparam DMEM_SEL_XMINUS	= 4'd2;
localparam DMEM_SEL_YPLUS	= 4'd3;
localparam DMEM_SEL_YMINUS	= 4'd4;
localparam DMEM_SEL_YQ		= 4'd5; // include DMEM_SEL_Y
localparam DMEM_SEL_ZPLUS	= 4'd6;
localparam DMEM_SEL_ZMINUS	= 4'd7;
localparam DMEM_SEL_ZQ		= 4'd8; // include DMEM_SEL_Z
localparam DMEM_SEL_SP_R	= 4'd9;
localparam DMEM_SEL_SP_PCL	= 4'd10;
localparam DMEM_SEL_SP_PCH	= 4'd11;
localparam DMEM_SEL_PMEM	= 4'd12;
localparam DMEM_SEL_SP_PCL_IRQ	= 4'd13; // push PC to SP automatically in IRQ routine ,added 11-10
localparam DMEM_SEL_SP_PCH_IRQ	= 4'd14; // 11-10

/* ALU */

reg normal_en;
reg lds_writeback;
reg st_write_reg;
reg set_i;
wire clear_i; // for interrupt handle, RETI 11-07

wire [4:0] write_dest = lds_writeback ? Rd_r : 
                        st_write_reg  ? dmem_a_int_reg :
                        Rd;

// synthesis translate_off
integer i_rst_regf;
// synthesis translate_on
reg [7:0] R;
reg writeback;
reg update_nsz;
reg change_z;
reg [15:0] R16;
reg mode16;
always @(posedge clk) begin
	R = 8'hxx;
	writeback = 1'b0;
	update_nsz = 1'b0;
	change_z = 1'b1;
	R16 = 16'hxxxx;
	mode16 = 1'b0;
	if(rst) begin
		/*
		 * Not resetting the register file enables the use of more efficient
		 * distributed block RAM.
		 */
		// synthesis translate_off
		for(i_rst_regf=0;i_rst_regf<24;i_rst_regf=i_rst_regf+1)
			GPR[i_rst_regf] = 8'd0;
		U = 16'd0;
		pX = 16'd0;
		pY = 16'd0;
		pZ = 16'd0;
		// synthesis translate_on
        I = 1'b0; // add 11-07
		T = 1'b0;
		H = 1'b0;
		S = 1'b0;
		V = 1'b0;
		N = 1'b0;
		Z = 1'b0;
		C = 1'b0;
	end else begin
		if(normal_en) begin
			writeback = 1'b1;
			update_nsz = 1'b1;
			casex(pmem_d)
				16'b000x_11xx_xxxx_xxxx: begin
					/* ADD - ADC */
					{C, R} = GPR_Rd + GPR_Rr + (pmem_d[12] & C);
					H = (GPR_Rd[3] & GPR_Rr[3])|(GPR_Rr[3] & ~R[3])|(~R[3] & GPR_Rd[3]);
					V = (GPR_Rd[7] & GPR_Rr[7] & ~R[7])|(~GPR_Rd[7] & ~GPR_Rr[7] & R[7]);
				end
				16'b000x_10xx_xxxx_xxxx, /* subtract */
				16'b000x_01xx_xxxx_xxxx: /* compare  */ begin
					/* SUB - SBC / CP - CPC */
					{C, R} = GPR_Rd - GPR_Rr - (~pmem_d[12] & C);
					H = (~GPR_Rd[3] & GPR_Rr[3])|(GPR_Rr[3] & R[3])|(R[3] & ~GPR_Rd[3]);
					V = (GPR_Rd[7] & ~GPR_Rr[7] & ~R[7])|(~GPR_Rd[7] & GPR_Rr[7] & R[7]);
					if(~pmem_d[12])
						change_z = 1'b0;
					writeback = pmem_d[11];
				end
				16'b010x_xxxx_xxxx_xxxx, /* subtract */
				16'b0011_xxxx_xxxx_xxxx: /* compare  */ begin
					/* SUBI - SBCI / CPI */
					{C, R} = GPR_Rd - K - (~pmem_d[12] & C);
					H = (~GPR_Rd[3] & K[3])|(K[3] & R[3])|(R[3] & ~GPR_Rd[3]);
					V = (GPR_Rd[7] & ~K[7] & ~R[7])|(~GPR_Rd[7] & K[7] & R[7]);
					if(~pmem_d[12])
						change_z = 1'b0;
					writeback = pmem_d[14];
				end
				16'b0010_00xx_xxxx_xxxx: begin
					/* AND */
					R = GPR_Rd & GPR_Rr;
					V = 1'b0;
				end
				16'b0111_xxxx_xxxx_xxxx: begin
					/* ANDI */
					R = GPR_Rd & K;
					V = 1'b0;
				end
				16'b0010_10xx_xxxx_xxxx: begin
					/* OR */
					R = GPR_Rd | GPR_Rr;
					V = 1'b0;
				end
				16'b0110_xxxx_xxxx_xxxx: begin
					/* ORI */
					R = GPR_Rd | K;
					V = 1'b0;
				end
				16'b0010_01xx_xxxx_xxxx: begin
					/* EOR */
					R = GPR_Rd ^ GPR_Rr;
					V = 1'b0;
				end
				16'b1001_010x_xxxx_0000: begin
					/* COM */
					R = ~GPR_Rd;
					V = 1'b0;
					C = 1'b1;
				end
				16'b1001_010x_xxxx_0001: begin
					/* NEG */
					{C, R} = 8'h00 - GPR_Rd;
					H = R[3] | GPR_Rd[3];
					V = R == 8'h80;
				end
				16'b1001_010x_xxxx_0011: begin
					/* INC */
					R = GPR_Rd + 8'd1;
					V = R == 8'h80;
				end
				16'b1001_010x_xxxx_1010: begin
					/* DEC */
					R = GPR_Rd - 8'd1;
					V = R == 8'h7f;
				end
				16'b1001_010x_xxxx_011x: begin
					/* LSR - ROR */
					R = {pmem_d[0] & C, GPR_Rd[7:1]};
					C = GPR_Rd[0];
					V = R[7] ^ GPR_Rd[0];
				end
				16'b1001_010x_xxxx_0101: begin
					/* ASR */
					R = {GPR_Rd[7], GPR_Rd[7:1]};
					C = GPR_Rd[0];
					V = R[7] ^ GPR_Rd[0];
				end
				16'b1001_010x_xxxx_0010: begin
					/* SWAP */
					R = {GPR_Rd[3:0], GPR_Rd[7:4]};
					update_nsz = 1'b0;
				end
				16'b1001_010x_xxxx_1000: begin
					/* BSET - BCLR */
					case(pmem_d[7:4])
						4'b0000: C = 1'b1;
						4'b0001: Z = 1'b1;
						4'b0010: N = 1'b1;
						4'b0011: V = 1'b1;
						4'b0100: S = 1'b1;
						4'b0101: H = 1'b1;
						4'b0110: T = 1'b1;
                        4'b0111: I = 1'b1; // add 11-07
						4'b1000: C = 1'b0;
						4'b1001: Z = 1'b0;
						4'b1010: N = 1'b0;
						4'b1011: V = 1'b0;
						4'b1100: S = 1'b0;
						4'b1101: H = 1'b0;
						4'b1110: T = 1'b0;
                        4'b1111: I = 1'b0; // add 11-07
					endcase
					update_nsz = 1'b0;
					writeback = 1'b0;
				end
				16'b1001_011x_xxxx_xxxx: begin
					mode16 = 1'b1;
					if(pmem_d[8]) begin
						/* SBIW */
						{C, R16} = GPR_Rd16 - K16;
						V = GPR_Rd16[15] & ~R16[15];
					end else begin
						/* ADIW */
						{C, R16} = GPR_Rd16 + K16;
						V = ~GPR_Rd16[15] & R16[15];
					end
				end
				/* SBR and CBR are replaced with ORI and ANDI */
				/* TST is replaced with AND */
				/* CLR and SER are replaced with EOR and LDI */
				16'b0010_11xx_xxxx_xxxx: begin
					/* MOV */
					R = GPR_Rr;
					update_nsz = 1'b0;
				end
				16'b1110_xxxx_xxxx_xxxx: begin
					/* LDI */
					R = K;
					update_nsz = 1'b0;
				end
				/* LSL is replaced with ADD */
				/* ROL is replaced with ADC */
				16'b1111_10xx_xxxx_0xxx: begin
					if(pmem_d[9]) begin
						/* BST */
						T = GPR_Rd_b;
						writeback = 1'b0;
					end else begin
						/* BLD */
						case(b)
							3'd0: R = {GPR_Rd[7:1], T};
							3'd1: R = {GPR_Rd[7:2], T, GPR_Rd[0]};
							3'd2: R = {GPR_Rd[7:3], T, GPR_Rd[1:0]};
							3'd3: R = {GPR_Rd[7:4], T, GPR_Rd[2:0]};
							3'd4: R = {GPR_Rd[7:5], T, GPR_Rd[3:0]};
							3'd5: R = {GPR_Rd[7:6], T, GPR_Rd[4:0]};
							3'd6: R = {GPR_Rd[7], T, GPR_Rd[5:0]};
							3'd7: R = {T, GPR_Rd[6:0]};
						endcase
					end
					update_nsz = 1'b0;
				end
				/* SEC, CLC, SEN, CLN, SEZ, CLZ, SEI, CLI, SES, CLS, SEV, CLV, SET, CLT, SEH, CLH
				 * are replaced with BSET and BCLR */
				16'b0000_0000_0000_0000: begin
					/* NOP */
					update_nsz = 1'b0;
					writeback = 1'b0;
				end
				/* SLEEP is not implemented */
				/* WDR is not implemented */
				16'b1001_00xx_xxxx_1111, /* PUSH/POP */
				16'b1001_00xx_xxxx_1100, /*  X   */
				16'b1001_00xx_xxxx_1101, /*  X+  */
				16'b1001_00xx_xxxx_1110, /* -X   */ 
				16'b1001_00xx_xxxx_1001, /*  Y+  */
				16'b1001_00xx_xxxx_1010, /* -Y   */
				16'b10x0_xxxx_xxxx_1xxx, /*  Y+q */
				16'b1001_00xx_xxxx_0001, /*  Z+  */
				16'b1001_00xx_xxxx_0010, /* -Z   */
				16'b10x0_xxxx_xxxx_0xxx: /*  Z+q */
				begin
					/* LD - POP (run from state WRITEBACK) */
					//R = dmem_di; /* Modified 11-05 */
                    R = dmem_di_int;
					update_nsz = 1'b0;
				end
				16'b1011_0xxx_xxxx_xxxx: begin
					/* IN (run from state WRITEBACK) */
					case(io_sel)
						IO_SEL_EXT: R = io_di;
						IO_SEL_STACK: R = io_sp;
						IO_SEL_SREG: R = {I, T, H, S, V, N, Z, C};
						default: R = 8'hxx;
					endcase
					update_nsz = 1'b0;
				end
			endcase
		end /* if(normal_en) */
		if(lds_writeback) begin
			//R = dmem_di; /* Modified 11-05 */
            R = dmem_di_int;
			writeback = 1'b1;
		end
        /* ST STS instruction access REG add 11-05 */
        if(st_write_reg) begin
            R = dmem_do_int;
            writeback = 1'b1;
        end /* */
		if(lpm_en) begin
			R = pZ[0] ? pmem_d[15:8] : pmem_d[7:0];
			writeback = 1'b1;
		end
		if(update_nsz) begin
			N = mode16 ? R16[15] : R[7];
			S = N ^ V;
			Z = mode16 ? R16 == 16'h0000 : ((R == 8'h00) & (change_z|Z));
		end
		if(io_we & (io_a == 6'b111111))
			{I, T, H, S, V, N, Z, C} = io_do[7:0]; // modified 11-07
		if(writeback) begin
			if(mode16) begin
				// synthesis translate_off
				//$display("REG WRITE(16): %d < %d", Rd16, R16);
				// synthesis translate_on
				case(Rd16)
					2'd0: U = R16;
					2'd1: pX = R16;
					2'd2: pY = R16;
					2'd3: pZ = R16;
				endcase
			end else begin
				// synthesis translate_off
				//$display("REG WRITE: %d < %d", Rd, R);
				// synthesis translate_on
				case(write_dest)
					default: GPR[write_dest] = R;
					5'd24: U[7:0] = R;
					5'd25: U[15:8] = R;
					5'd26: pX[7:0] = R;
					5'd27: pX[15:8] = R;
					5'd28: pY[7:0] = R;
					5'd29: pY[15:8] = R;
					5'd30: pZ[7:0] = R;
					5'd31: pZ[15:8] = R;
				endcase
			end
		end else begin /* if(writeback) */
			case(dmem_sel)
				DMEM_SEL_XPLUS:		pX = pX + 16'd1;
				DMEM_SEL_XMINUS:	pX = pX - 16'd1;
				DMEM_SEL_YPLUS:		pY = pY + 16'd1;
				DMEM_SEL_YMINUS:	pY = pY - 16'd1;
				DMEM_SEL_ZPLUS:		pZ = pZ + 16'd1;
				DMEM_SEL_ZMINUS:	pZ = pZ - 16'd1;
				default:;
			endcase
		end
        if(set_i) /* update flag I in SREG when into interrupt or RETI add 11-07 */
            I = 1'b1;
        else if(clear_i)
            I = 1'b0;
	end /* if(rst) ... else */
end

/* I/O port */
// generate I/O address
always @(*) begin // added 11-03
    casex(pmem_d[15:10]) // fix a bug 12-28
        6'b1001_10:            io_a = {1'b0, pmem_d[7:3]}; // io_a = 0~31 SBIC SBIS SBI CBI
        6'b1011_xx:            io_a = {pmem_d[10:9], pmem_d[3:0]}; // io_a = 0~63 IN OUT
        default:            io_a = dmem_a_int_io; // LD ST LDS STS instruction access I/O space
    endcase
end
// assign io_a = {pmem_d[10:9], pmem_d[3:0]}; modified 11-03

// generate I/O data out
reg [7:0] io_data_modified; // internal wire connected to io_do when execute SBI CBI
// assign io_do = GPR_Rd;
always @(*) begin
    casex(pmem_d[15:8])
        8'b1001_10x0:       io_do = io_data_modified; // SBI CBI
        8'b1011_1xxx:       io_do = GPR_Rd; // OUT add 11-05
        default:            io_do = dmem_do_int; // ST STS modified 11-05
    endcase
end

/* Data memory */
// generate data memory address for LD & ST instruction
always @(*) begin
	case(dmem_sel)
		DMEM_SEL_X,
		DMEM_SEL_XPLUS:		    dmem_a_int = pX;
		DMEM_SEL_XMINUS:	    dmem_a_int = pX - 16'd1;
		DMEM_SEL_YPLUS:		    dmem_a_int = pY;
		DMEM_SEL_YMINUS:	    dmem_a_int = pY - 16'd1;
		DMEM_SEL_YQ:		    dmem_a_int = pY + q;
		DMEM_SEL_ZPLUS:		    dmem_a_int = pZ;
		DMEM_SEL_ZMINUS:	    dmem_a_int = pZ - 16'd1;
		DMEM_SEL_ZQ:		    dmem_a_int = pZ + q;
		DMEM_SEL_SP_R,
		DMEM_SEL_SP_PCL,
		DMEM_SEL_SP_PCH,
        DMEM_SEL_SP_PCL_IRQ, // 11-10
        DMEM_SEL_SP_PCH_IRQ:	dmem_a_int = SP + pop; // 11-10
		DMEM_SEL_PMEM:		    dmem_a_int = pmem_d;
		default:		        dmem_a_int = {dmem_width{1'bx}};
	endcase
end


wire [pmem_width-1:0] PC_inc = PC + {{pmem_width-1{1'b0}}, 1'b1};
always @(*) begin
	case(dmem_sel)
		DMEM_SEL_X,
		DMEM_SEL_XPLUS,
		DMEM_SEL_XMINUS,
		DMEM_SEL_YPLUS,
		DMEM_SEL_YMINUS,
		DMEM_SEL_YQ,
		DMEM_SEL_ZPLUS,
		DMEM_SEL_ZMINUS,
		DMEM_SEL_ZQ,
		DMEM_SEL_SP_R:		    dmem_do_int = GPR_Rd;
		DMEM_SEL_SP_PCL:	    dmem_do_int = PC_inc[7:0];
        DMEM_SEL_SP_PCL_IRQ:    dmem_do_int = PC[7:0]; // 11-10
		DMEM_SEL_SP_PCH:	    dmem_do_int = PC_inc[pmem_width-1:8];
        DMEM_SEL_SP_PCH_IRQ:	dmem_do_int = PC[pmem_width-1:8]; // 11-10
		DMEM_SEL_PMEM:		    dmem_do_int = GPR_Rd_r;
		default:		        dmem_do_int = 8'hxx;
	endcase
end

/* Multi-cycle operation sequencer */

wire reg_equal = GPR_Rd == GPR_Rr;

reg sreg_read;
always @(*) begin
	case(b)
		3'd0: sreg_read = C;
		3'd1: sreg_read = Z;
		3'd2: sreg_read = N;
		3'd3: sreg_read = V;
		3'd4: sreg_read = S;
		3'd5: sreg_read = H;
		3'd6: sreg_read = T;
		3'd7: sreg_read = 1'b0;
        default: ;
	endcase
end

reg io_read; // io bit read added 11-03
always @(*) begin
    case(b)
        3'd0: io_read = io_di[0];
		3'd1: io_read = io_di[1];
		3'd2: io_read = io_di[2];
		3'd3: io_read = io_di[3];
		3'd4: io_read = io_di[4];
		3'd5: io_read = io_di[5];
		3'd6: io_read = io_di[6];
		3'd7: io_read = io_di[7];
        default: ;
    endcase
end

reg [3:0] state;
reg [3:0] next_state;

localparam NORMAL   	= 4'd0;
localparam RCALL		= 4'd1;
localparam ICALL		= 4'd2;
localparam STALL		= 4'd3;
localparam RET1	    	= 4'd4;
localparam RET2	    	= 4'd5;
localparam RET3	    	= 4'd6;
localparam LPM	    	= 4'd7;
localparam STS	    	= 4'd8;
localparam LDS1	    	= 4'd9;
localparam LDS2	    	= 4'd10;
localparam SKIP		    = 4'd11;
localparam WRITEBACK	= 4'd12;
localparam SBI          = 4'd13; /* SBIC SBIS added 2011-11-03 */ 
localparam IRQ1         = 4'd14;
localparam IRQ2         = 4'd15;


always @(posedge clk) begin
	if(rst)
		state <= NORMAL;
	else if(irq_start) /* handle IRQ */
        state <= IRQ1;
    else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	pmem_ce = rst;

	pc_sel = PC_SEL_NOP;
	normal_en = 1'b0;
	lpm_en = 1'b0;

	io_re = 1'b0;
	io_we = 1'b0;

	dmem_we = 1'b0;
	dmem_sel = DMEM_SEL_UNDEFINED;

	push = 1'b0;
	pop = 1'b0;

	pmem_selz = 1'b0;

	regmem_ce = 1'b1;
	lds_writeback = 1'b0;
    
    io_data_modified = 8'd0; /* I/O write back data for SBI CBI */
    
    st_write_reg = 1'b0; /* ST STS instruction access REG */
    
    set_i = 1'b0;
    irqack = 1'b0;
    
	
	case(state)
		NORMAL: begin
			casex(pmem_d)
				16'b1100_xxxx_xxxx_xxxx: begin
					/* RJMP */
					pc_sel = PC_SEL_KL;
					next_state = STALL;
				end
				16'b1101_xxxx_xxxx_xxxx: begin
					/* RCALL */
					dmem_sel = DMEM_SEL_SP_PCL;
					dmem_we = 1'b1;
					push = 1'b1;
					next_state = RCALL;
				end
				16'b0001_00xx_xxxx_xxxx: begin
					/* CPSE */
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
					if(reg_equal)
						next_state = SKIP;
				end
				16'b1111_11xx_xxxx_0xxx: begin
					/* SBRC - SBRS */
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
					if(GPR_Rd_b == pmem_d[9])
						next_state = SKIP;
				end
                /* added 11-03 */
                16'b1001_10xx_xxxx_xxxx: begin
                    /* SBIC - SBIS, SBI - CBI */
                    io_re = 1'b1; // read I/O at the end of this state
                    next_state = SBI;
                end
				16'b1111_0xxx_xxxx_xxxx: begin
					/* BRBS - BRBC */
					pmem_ce = 1'b1;
					if(sreg_read ^ pmem_d[10]) begin
						pc_sel = PC_SEL_KS;
						next_state = STALL;
					end else
						pc_sel = PC_SEL_INC;
				end
				/* BREQ, BRNE, BRCS, BRCC, BRSH, BRLO, BRMI, BRPL, BRGE, BRLT,
				 * BRHS, BRHC, BRTS, BRTC, BRVS, BRVC, BRIE, BRID are replaced
				 * with BRBS/BRBC */
                 /* All LD ST instrcution address selection decode modified 2011-11-05 */
				16'b1001_00xx_xxxx_1100, /*  X   */
				16'b1001_00xx_xxxx_1101, /*  X+  */
				16'b1001_00xx_xxxx_1110, /* -X   */ 
				16'b1001_00xx_xxxx_1001, /*  Y+  */
				16'b1001_00xx_xxxx_1010, /* -Y   */
				16'b10x0_xxxx_xxxx_1xxx, /*  Y+q */
				16'b1001_00xx_xxxx_0001, /*  Z+  */
				16'b1001_00xx_xxxx_0010, /* -Z   */
				16'b10x0_xxxx_xxxx_0xxx: /*  Z+q */
				begin
					casex({pmem_d[12], pmem_d[3:0]})
						5'b1_1100: dmem_sel = DMEM_SEL_X;
						5'b1_1101: dmem_sel = DMEM_SEL_XPLUS;
						5'b1_1110: dmem_sel = DMEM_SEL_XMINUS;
						5'b1_1001: dmem_sel = DMEM_SEL_YPLUS;
						5'b1_1010: dmem_sel = DMEM_SEL_YMINUS;
						5'b0_1xxx: dmem_sel = DMEM_SEL_YQ; // include LD Rd, Y ST Rd, Y
						5'b1_0001: dmem_sel = DMEM_SEL_ZPLUS;
						5'b1_0010: dmem_sel = DMEM_SEL_ZMINUS;
						5'b0_0xxx: dmem_sel = DMEM_SEL_ZQ; // include LD Rd, Z ST Rd, Z
                        default: ;
					endcase
					if(pmem_d[9]) begin
						/* ST */
						pc_sel = PC_SEL_INC;
						pmem_ce = 1'b1;
                        // store data to external sram modified 11-05
                        case(dmem_a_sel)
                            DMEM_A_SEL_SRAM: dmem_we = 1'b1;
                            DMEM_A_SEL_IO:   io_we = 1'b1;
                            DMEM_A_SEL_REG : st_write_reg = 1'b1;
                            default: ;
                        endcase	
					end else begin
						/* LD */
                        if(dmem_a_sel == DMEM_A_SEL_IO)
                            io_re = 1'b1;
						next_state = WRITEBACK;
					end
				end
				16'b1011_0xxx_xxxx_xxxx: begin
					/* IN */
					io_re = 1'b1;
					next_state = WRITEBACK;
				end
				16'b1011_1xxx_xxxx_xxxx: begin
					/* OUT */
					io_we = 1'b1;
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
				end
				16'b1001_00xx_xxxx_1111: begin
					if(pmem_d[9]) begin
						/* PUSH */
						push = 1'b1;
						dmem_sel = DMEM_SEL_SP_R;
						dmem_we = 1'b1;
						pc_sel = PC_SEL_INC;
						pmem_ce = 1'b1;
					end else begin
						/* POP */
						pop = 1'b1;
						dmem_sel = DMEM_SEL_SP_R;
						next_state = WRITEBACK;
					end
                end
                16'b1001_00xx_xxxx_0000: begin
						pc_sel = PC_SEL_INC;
						pmem_ce = 1'b1;
						if(pmem_d[9])
							/* STS */
							next_state = STS;
						else
							/* LDS */
							next_state = LDS1;
				end
				16'b1001_0101_000x_1000: begin
					/* RET - RETI  */
                    /* RETI is the same as RET except set I flag when return */
                    set_i = pmem_d[4]; /* set I in SREG when execute RETI instruction */
					dmem_sel = DMEM_SEL_SP_PCH;
					pop = 1'b1;
					next_state = RET1;
				end
				16'b1001_0101_1100_1000: begin
					/* LPM */
					pmem_selz = 1'b1;
					pmem_ce = 1'b1;
					next_state = LPM;
				end
				16'b1001_0100_0000_1001: begin
					/* IJMP */
					pc_sel = PC_SEL_Z;
					next_state = STALL;
				end
				16'b1001_0101_0000_1001: begin
					/* ICALL */
					dmem_sel = DMEM_SEL_SP_PCL;
					dmem_we = 1'b1;
					push = 1'b1;
					next_state = ICALL;
				end
				default: begin
					pc_sel = PC_SEL_INC;
					normal_en = 1'b1;
					pmem_ce = 1'b1;
				end
			endcase
		end
		RCALL: begin
			dmem_sel = DMEM_SEL_SP_PCH;
			dmem_we = 1'b1;
			push = 1'b1;
			pc_sel = PC_SEL_KL;
			next_state = STALL;
		end
		ICALL: begin
			dmem_sel = DMEM_SEL_SP_PCH;
			dmem_we = 1'b1;
			push = 1'b1;
			pc_sel = PC_SEL_Z;
			next_state = STALL;
		end
		RET1: begin
			pc_sel = PC_SEL_DMEMH;
			dmem_sel = DMEM_SEL_SP_PCL;
			pop = 1'b1;
			next_state = RET2;
		end
		RET2: begin
			pc_sel = PC_SEL_DMEML;
			next_state = RET3;
		end
		RET3: begin
			pc_sel = PC_SEL_DEC;
			next_state = STALL;
		end
		LPM: begin
			lpm_en = 1'b1;
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			next_state = NORMAL;
		end
		STS: begin
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			dmem_sel = DMEM_SEL_PMEM;
            case(dmem_a_sel)
                DMEM_A_SEL_SRAM: dmem_we = 1'b1;
                DMEM_A_SEL_IO:   io_we = 1'b1;
                DMEM_A_SEL_REG : st_write_reg = 1'b1;
                default: ;
            endcase
			next_state = NORMAL;
		end
		LDS1: begin
			dmem_sel = DMEM_SEL_PMEM;
            case(dmem_a_sel)
                DMEM_A_SEL_SRAM:
                begin
                    regmem_ce = 1'b0;
                    next_state = LDS2;
                end
                DMEM_A_SEL_IO:
                begin
                    regmem_ce = 1'b0;
                    io_re = 1'b1;
                    next_state = LDS2;
                end
                DMEM_A_SEL_REG:
                begin
                    pc_sel = PC_SEL_INC;
                    pmem_ce = 1'b1;
                    lds_writeback = 1'b1;
                    next_state = NORMAL;
                end
                default: ;
            endcase;
		end
		LDS2: begin
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			lds_writeback = 1'b1;
			next_state = NORMAL;
		end
		SKIP: begin
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			/* test for STS and LDS */
			if((pmem_d[15:10] == 6'b100100) & (pmem_d[3:0] == 4'h0))
				next_state = STALL; /* 2-word instruction, skip the second word as well */
			else
				next_state = NORMAL; /* 1-word instruction */
		end
		STALL: begin
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			next_state = NORMAL;
		end
		WRITEBACK: begin
			pmem_ce = 1'b1;
			pc_sel = PC_SEL_INC;
			normal_en = 1'b1;
			next_state = NORMAL;
		end
        SBI: begin /* support SBIS SBIC SBI CBI instruction ,added 11-03 */
            pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
            if(pmem_d[8]) begin
                if(pmem_d[9])  /* SBIS */
                    next_state = io_read ? SKIP : NORMAL;
                else  /* SBIC */
                    next_state = io_read ? NORMAL : SKIP;
            end else begin
                next_state = NORMAL;
                io_we = 1'b1; /* io data write back */
                if(pmem_d[9]) begin /* SBI */
                    io_data_modified = io_di | (8'd1 << b);
                end else begin /* SBC */
                    io_data_modified = io_di & ~(8'd1 << b);
                end
            end
        end
        IRQ1: begin
            dmem_sel = DMEM_SEL_SP_PCL_IRQ;
			dmem_we = 1'b1;
			push = 1'b1;
            irqack = 1'b1;
            next_state = IRQ2;
        end
        IRQ2: begin
            dmem_sel = DMEM_SEL_SP_PCH_IRQ;
			dmem_we = 1'b1;
			push = 1'b1;
            pc_sel = PC_SEL_IRQ; /* load interrupt vector */
            next_state = RET3; /* decrease pc by 1, for pmem_a = pc + 1 */
        end
	endcase
end

/* Interrupt add 11-07 */
reg [3:0] irq_vector_addr; /* interrupt vector */

/* Interrupt vector artibiter */
always @*
begin
    irq_vector_addr = 4'b0000; /* RESET */
    if(irqlines[0] == 1'b1 )        irq_vector_addr[3:0] = 4'b0001; /* 0x0001 */
    else if(irqlines[1] == 1'b1)    irq_vector_addr[3:0] = 4'b0010; /* 0x0002 */
    else if(irqlines[2] == 1'b1)    irq_vector_addr[3:0] = 4'b0011; /* 0x0003 */
    else if(irqlines[3] == 1'b1)    irq_vector_addr[3:0] = 4'b0100; /* 0x0004 */
    else if(irqlines[4] == 1'b1)    irq_vector_addr[3:0] = 4'b0101; /* 0x0005 */
    else if(irqlines[5] == 1'b1)    irq_vector_addr[3:0] = 4'b0110; /* 0x0006 */
    else if(irqlines[6] == 1'b1)    irq_vector_addr[3:0] = 4'b0111; /* 0x0007 */
    else if(irqlines[7] == 1'b1)    irq_vector_addr[3:0] = 4'b1000; /* 0x0008 */
    else if(irqlines[8] == 1'b1)    irq_vector_addr[3:0] = 4'b1001; /* 0x0009 */
    else if(irqlines[9] == 1'b1)    irq_vector_addr[3:0] = 4'b1010; /* 0x000A */
end

wire irq_int, irq_start, cpu_busy;
assign irq_int = irqlines == {8{1'b0}} ? 1'b0 : 1'b1; /* interrupt indicate */
/* wait all multi-cycle execution finished */
assign cpu_busy =   (next_state != NORMAL) || /* next_state == NORMAL is last clk cycle of instruction */
                    ((state == NORMAL) && (pmem_d == 16'b1001_0100_1111_1000)) || /* CLI */
                    /* Writing '0' to I flag (OUT/STD/ST/STD) */
                    ((io_do[7] == 1'b0) && (io_a == 6'b111111) &&(io_we == 1'b1)) ||
                    /* At least one instruction must be executed after RETI and before the new interrupt. */
                    ((state == STALL) && (pmem_d == 16'b1001_0101_0001_1000));

 /* indicate toggle when current instruction finished & interrupt enable */                    
assign irq_start = ~cpu_busy && I && irq_int; 
assign clear_i = irq_start;

/* register IRQ address */
always @(posedge clk)
begin
    if(rst)
        irqackad <= 4'b0000;
    else if(irq_start)
        irqackad <= irq_vector_addr;
end




endmodule
