// this version based on http://moxi.jp/wiki/wiki.cgi?page=Intel+Hex+%A4%F2+Xilinx+coe+%A4%CB%CA%D1%B4%B9%A4%B9%A4%EB
// Modify to fit AVR-GCC generate hex file.
// Xilinx ROM has 16-bit data widths. 
#include <stdio.h>
#include <stdlib.h>

#define LINEMAX 0x100

#define DEFAULT_SIZE 0x400 /* default 1K Word (16 bit) memory cells. */

/* pseudo memory space */
unsigned char memory[0x10000] ; /* max 64Kbyte Space , that's enough for comment FPGA blockram */

/* hex to decimal converter */
static int hextoint(char a)
{
	if ((a >= '0') && (a <='9')) return a - '0' ;
	if ((a >= 'A') && (a <='F')) return a - 'A' + 0x0A ;
	if ((a >= 'a') && (a <='f')) return a - 'a' + 0x0A ;
	return 0 ;
}

static int hex2toint(char *a)
{
	return (hextoint(a[0]) * 0x10 +  hextoint(a[1])) ;
}

static int hex4toint(char *a)
{
	return (hextoint(a[0]) * 0x1000 +   hextoint(a[1]) * 0x100 + hextoint(a[2])*0x10 +  hextoint(a[3])) ;
}

void main(int argc,char *argv[])
{
	char line[LINEMAX] ;
	unsigned int memend,memtop,i,j ;
	FILE *fpi,*fpo ;

	memend = 0x0000 ; /* end address of vaild data */
	memtop = DEFAULT_SIZE - 1; /* end address of ROM */
	
	printf("Intel HEX to Altera memory initfile converter (16bit).\n",argv[0]) ;
 
	/* help message */
	if (argc < 3 || argc > 4) {
		fprintf(stderr,"(1)\t%s [infile.hex] [outfile.mif]\n"
						  "\tDefault 2KB ROM file.\n", argv[0]);
		fprintf(stderr, "(2)\t%s [infile.hex] [outfile.mif] [size( in KByte)]\n"
			               "\tMax 64KB size ROM file.\n", argv[0]); // Added 11-04
			// Add comment 2011-10-15
		fprintf(stderr,"Only for AVR GCC generated Hex file.\n");
		fprintf(stderr,"Modified from http://moxi.jp 's Intel Hex to Xilinx coe program.\n");
		fprintf(stderr,"version 1.1.0 wang:)\n");
		exit(-1) ;
	}
	else if(argc == 3)
		printf("Use default ROM size 2KByte (1K Words in 16bit ).\n ");
	else {
		if((0 == sscanf(argv[3], "%u", &memtop)) || memtop > 64) {
			fprintf(stderr,"Paramter error, size range from 1 - 64 KB, 1KB step.\n");
			exit(-1);
		}
		else {
			memtop = memtop * 512- 1; // 16-bit word in ROM cell.
		}
	}

	/* open input file */
	if ((fpi = fopen(argv[1],"r")) == NULL) {
		fprintf(stderr,"Can't open input file [%s]\n",argv[1]) ;
		exit(-1) ;
	}

	/* read hex file and distribute bits */
	while(fgets(line,LINEMAX,fpi) != NULL) {
		unsigned int reclen,recofs,rectyp ;

		/* +0123456789A            */
		/*  :LLOOOOTTDD...DDCC[CR] */
		/*  LL   - Data Count */
		/*  OOOO - Offset Address */
		/*  TT   - Record Type, 00 : DATA , 01 : END , ignore other types */

		/* [0] is always ':' */
		if (line[0] != ':') continue ;

		/* [1,2] is record length */
		reclen = hex2toint(&line[1]) ;
		if (reclen == 0) continue ;

		/* [3,4,5,6] is record offset */
		recofs = hex4toint(&line[3]) ;

		/* [7,8] is recore type */
		rectyp = hex2toint(&line[7]) ;
		if (rectyp != 0) continue ; /* 01 is END but ignore here */

		/* write one record to pseudo memory (no error check :-) */
		for (i = 0;i < reclen;i++) {
			int data ;
			data = hex2toint(&line[9+i*2]) ;
			memory[recofs] = (unsigned char)data & 0xFF;
			if (recofs > memend) memend = recofs ;
			recofs ++ ;
		}
	}
	fclose(fpi) ;

//#define DEBUG
#ifdef DEBUG
	/* dump memory map (for DEBUG) */
	printf("Read %d bytes from hex file.\n", memend + 1); // display hex size. 2011-10-15
	printf("Memory Content is .... (Address is in 16-radix)\n") ;
	for (i = 0;i <= memend;i += 16) {
		unsigned int j ;
		printf("%04X :",i) ;
		for (j = i;(j < i + 16) && (j <= memend);j++) {
			printf(" %02X",memory[j]) ;
		}
		printf("\n") ;
	}
#endif

	// byte count is odd. verify byte number. 2011-10-15
	if(!memend/2)	{
		printf("Wrong Byte number. Abort!\n");
			exit(-1);
	}

	/* open output file */
	if ((fpo = fopen(argv[2],"w"))== NULL) {
		fprintf(stderr,"Can't open output file [%s]\n",argv[2]) ;
		exit(-1) ;
	}

	/* Output .mif header format */
	fprintf(fpo,"WIDTH=16;\n");
	fprintf(fpo,"DEPTH=%u;\n\n", memtop + 1);
	fprintf(fpo,"ADDRESS_RADIX=HEX;\n");
	fprintf(fpo,"DATA_RADIX=HEX;\n");
	fprintf(fpo,"CONTENT BEGIN\n");
	/* Ouput ROM data */
	for (i = 0, j = 0;j < memend; j += 2, i++)	// modify for 16bit length generation. 2011-10-15
 		fprintf(fpo,"\t%03X  :   %02X%02X;\n", i, memory[j+1], memory[j]) ; // high address first.
	
	if(i < memtop)
		fprintf(fpo,"\t[%03X..%03X]  :   0000;\n", i, memtop) ;
	fprintf(fpo,"END;\n") ;
	fclose(fpo) ;

	printf("Filename:%s.\tROM Size:%sKByte.\n", argv[2], (argc == 3 ? "2" : argv[3])); /* Add 11-04 */
	
	exit(0);
}