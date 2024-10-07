`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: Wrapper
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: Wrapper for RISC-V processor. Not meant to be synthesized directly.
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface SHOULD NOT be modified unless you modify TOP.vhd too. The implementation can be modified.
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file as well as any files derived from this.
----------------------------------------------------------------------------------
*/

//>>>>>>>>>>>> ******* FOR SIMULATION. DO NOT SYNTHESIZE THIS DIRECTLY (This is used as a component in TOP.vhd for Synthesis) ******* <<<<<<<<<<<<


/*
******* New features in V2 *******
- Abilty to use the hexadecimal text dump from RARS directly without any conversion software or copy-pasting needed.
- Instruction and data memory sizes can be bigger than 128 words. Be mindful of the potentially increased synthesis time though.
- Addresses except IROM_BASE and DATA_MEM_BASE are heirarhically derived instead of hard-coding
- Byte and half-word writes to data memory and 7-segment display (sb and sh support) - aligned memory addresses and pre-shifted/aligned data required. Please read the relevant comments carefully.
- 	Note: byte and half-word read doesn't require any Wrapper support - you can simply read the whole byte, extract the byte/half-word and extend as necessary.
- Possible to use a different Memory Configuration from RARS, *except* supporing 32'hFFFF0000 as the MMIO base in the RARS default. MMIO_BASE = DRAM_BASE + 2**DRAM_DEPTH_BITS in all configs.
- Possible to use block RAMs (sync read) for instruction and data memories in pipelined version. Allows faster synthesis times and possibly clock rates for larger memory sizes.
- Renamed for simplicity and parity with assembly program labels: INSTR_MEM->IROM; DATA_CONST_MEM->DROM; DATA_VAR_MEM->DRAM
- Needs RVv2.v, and ProgramCounterv2.v (necessary only if the Memory Configuration is changed in RARS).
*/

/*
V2:
To use FPGA block RAMs for instruction and data memories in pipelined version (Allows faster synthesis times and possibly clock rates for larger memory sizes):
To use this (Disclaimer: Not tested fully), Uncomment line 225. Comment 231 to 233. Change 238, 248, 255, 273 to always@(posedge clk)
If enabled, Instr, ReadData_in are delayed by 1 cycle. Therefore, what you get can be used as InstrD, ReadDataW directly. MMIO reads are also delayed. 
The required byte/half-word will still have to be extracted from ReadDataW and zero/sign extended in W stage if using lb/lbu/lh/lhu.
*/

module Wrapper
#(
	parameter N_LEDs_OUT = 8,        // Number of LEDs displaying Result. LED(15 downto 15-N_LEDs_OUT+1). 8 by default
	parameter N_DIPs = 16,           // Number of DIPs. 16 by default
	parameter N_PBs  = 3             // Number of PushButtons. 3 by default
		                             // [2:0] -> BTNL, BTNC, BTNR. Note that BTNU is used as PAUSE and BTND is used as RESET
)
(
	input  [N_DIPs-1:0] DIP, 		 		// DIP switch inputs. Not debounced. Mapped to DIP_ADDRESS. 
	                                        // Only the least significant 16 bits read from this location are valid. 
	input  [N_PBs-1:0] PB,  				// PB switch inputs. Not debounced.	Mapped to PB_ADDRESS. 
	                                        // Only the least significant 3 bits read from this location are valid. Order (2 downto 0) ->  BTNL, BTNC, BTNR
	output reg [N_LEDs_OUT-1:0] LED_OUT, 	// LED(15 downto 8) mapped to LED_ADDRESS. Only the least significant 8 bits written to this location are used.
	output [6:0] LED_PC, 					// LED(6 downto 0) showing PC(8 downto 2).
	output reg [31:0] SEVENSEGHEX, 			// 7 Seg LED Display. Mapped to SEVENSEG_ADDRESS. The 32-bit value will appear as 8 Hex digits on the display.
	output reg [7:0] CONSOLE_OUT,           // CONSOLE (UART) Output. Mapped to CONSOLE_ADDRESS. The least significant 8 bits written to this location are sent to PC via UART.
											// Check if CONSOLE_OUT_ready (CONSOLE_OUT_ready_ADDRESS) is set before writing to this location (especially if your CLK_DIV_BITS is small).
											// Consecutive STRs to this location not permitted (there should be at least 1 instruction gap between STRs to this location).
	input	CONSOLE_OUT_ready,				// An indication to the wrapper/processor that it is ok to write to the CONSOLE_OUT (UART hardware).
	                                        //  This bit should be set in the testbench to indicate that it is ok to write a new character to CONSOLE_OUT from your program.
	                                        //  It can be read from the address CONSOLE_OUT_ready_ADDRESS.
	output reg CONSOLE_OUT_valid,           // An indication to the UART hardware that the processor has written a new data byte to be transmitted.
	input  [7:0] CONSOLE_IN,                // CONSOLE (UART) Input. Mapped to CONSOLE_ADDRESS. The least significant 8 bits read from this location is the character received from PC via UART.
	                                        // Check if CONSOLE_IN_valid flag (CONSOLE_IN_valid_ADDRESS)is set before reading from this location.
											// Consecutive LDRs from this location not permitted (needs at least 1 instruction spacing between LDRs).
											// Also, note that there is no Tx FIFO implemented. DO NOT send characters from PC at a rate faster than 
											//  your processor (program) can read them. This means sending only 1 char every few seconds if your CLK_DIV_BITS is 26.
											// 	This is not a problem if your processor runs at a high speed.
	input  	CONSOLE_IN_valid,               // An indication to the wrapper/processor that there is a new data byte waiting to be read from the UART hardware.
	                                        // This bit should be set in the testbench to indicate a new character (Else, the processor will only read in 0x00).
											//  It can be read from the address CONSOLE_IN_valid_ADDRESS.
	output reg CONSOLE_IN_ack,              // An indication to the UART hardware that the processor has read the newly received data byte.
	                                        // The testbench should clear CONSOLE_IN_valid when this is set.
	input  RESET,							// Active high. Implemented in TOP as not(CPU_RESET) or Internal_reset (CPU_RESET is red push button and is active low).
	input  CLK								// Divided Clock from TOP.
);


//----------------------------------------------------------------
// V2: Sizes of various segments, base addresses, and peripheral address offsets.
//----------------------------------------------------------------
// Set number of bits for the byte address. 
// Depth (size) = 2**DEPTH_BITS. e.g.,if DEPTH_BITS = 9, depth = 512 bytes = 128 words. 
// Make sure that the align directive in the assembly programme is set according to the sizes of the various segments.
// The size of a data segment affects the *next* segment alignment and address.
// Keep in mind that large memory sizes can cause synthesis times to be longer, esp if not using synch read (block RAM)

localparam IROM_DEPTH_BITS = 9; 
localparam DROM_DEPTH_BITS = 9;
localparam DRAM_DEPTH_BITS = 9;

// Base addresses of various segments
// The RARS default memory configuration is IROM_BASE = 32'h00400000 and DATA_MEM_BASE = 32'h10010000 in RARS.
// The RARS default MMIO base is 32'hFFFF0000, but this is hard to support. So we use MMIO_BASE = DRAM_BASE + 2**DRAM_DEPTH_BITS in all memory configurations
// We use compact memory configuration with .txt at 0 where IROM_BASE = 32'h00000000 and DATA_MEM_BASE = 32'h00002000
// Do not use absolute addresses (e.g., using li pseudoinstruction for addresses) for memory/MMIO unless you know what you are doing. If you are building on the sample HelloWorld, use la for SEVENSEG.
//  Relative addresses (e.g., la pseudoinstruction) works fine for all starting addresses and segment sizes

localparam IROM_BASE = 32'h00000000;   // make sure this is the .txt address set in the assembler/linker, 
                                            // and the PC default value as well as reset value in **ProgramCounter.v** 
localparam DATA_MEM_BASE = 32'h00002000;    // make sure this is the .data address set in the assembler/linker
localparam DROM_BASE = DATA_MEM_BASE + 32'h00000000;
localparam DRAM_BASE = DROM_BASE + 2**DROM_DEPTH_BITS;
localparam MMIO_BASE = DRAM_BASE + 2**DRAM_DEPTH_BITS;    // assuming MMIO is also in the .data segment

// Memory-mapped peripheral offsets
localparam LED_ADDRESS = MMIO_BASE + 32'h00000000;          //WO
localparam DIP_ADDRESS = MMIO_BASE + 32'h00000004;          //RO
localparam PB_ADDRESS  = MMIO_BASE + 32'h00000008;          //RO
localparam CONSOLE_ADDRESS = MMIO_BASE + 32'h0000000C;      //RW
localparam CONSOLE_IN_valid_ADDRESS = MMIO_BASE + 32'h00000010;     //RO, status bit
localparam CONSOLE_OUT_ready_ADDRESS = MMIO_BASE + 32'h000000014;   //RO, status bit
localparam SEVENSEG_ADDRESS = MMIO_BASE + 32'h00000018;     //WO
                                      
//----------------------------------------------------------------
// RV signals
//----------------------------------------------------------------
wire[31:0] PC ;
reg [31:0] Instr ;
reg[31:0] ReadData_in ;
wire MemRead ;
wire [3:0] MemWrite_out ;
wire[31:0] ALUResult ;
wire[31:0] WriteData_out ;

//----------------------------------------------------------------
// Address Decode signals
//---------------------------------------------------------------
wire dec_DROM, dec_DRAM, dec_LED, dec_DIP, dec_CONSOLE, dec_PB, dec_SEVENSEG, dec_CONSOLE_IN_valid, dec_CONSOLE_OUT_ready, dec_MMIO;  // 'enable' signals from data memory address decoding
reg dec_DROM_W, dec_DRAM_W, dec_MMIO_W;  // delayed versions of the decoded signals for output multiplexing

//----------------------------------------------------------------
// Memory declaration
//-----------------------------------------------------------------
reg [31:0] IROM	[0:2**(IROM_DEPTH_BITS-2)-1];	// instruction memory aka IROM
reg [31:0] DROM	[0:2**(DROM_DEPTH_BITS-2)-1];	// data (constant) memory aka DROM
reg [31:0] DRAM	[0:2**(DRAM_DEPTH_BITS-2)-1];	// data (variable) memory aka DRAM


//----------------------------------------------------------------
// V2: Memory initialisations
//----------------------------------------------------------------
initial begin
// Make sure that IROM.mem and DROM.mem (hexadecimal text memory dump from RARS - name it with .mem extension) are added to the project as 'Design Sources'. Alternatively, specify the full path.
// If you checked "Copy sources into project", make sure that subsequent dumps from RARS are to projectName/projectName.srcs/sources_1/imports/orignalSourceFolderName 
// "Copy sources into project" might be a bad idea. RARS does not remember the last opened folder, so keep it in a folder that is easier to access.
// IMP: "Relaunch Simulation" (top menu broken clock-wise button) may not enough if you change your .mem file. Do SIMULATION > Run Simulation > Run Behavioural Simulation.
// In simulation, check the memory contents under test_Wrapper>dut (Wrapper)> IROM (and other memories) if unsure the correct contents are used.
$readmemh("IROM.mem", IROM);
$readmemh("DROM.mem", DROM);	// This will generate a warning of having more than necessary data as the assembler dumps the entire data segment including DROM and MMIO,
								// This is ok as only the first part of it will be used to initialize DROM.
// DRAM should not be initalized. Initialization works for RAMs in FPGAs, but not for standard RAMs. You must store before you can load.
end

//----------------------------------------------------------------
// Memory and Peripheral outputs to be multiplexed
//----------------------------------------------------------------
reg [31:0] ReadData_DROM ;
reg [31:0] ReadData_DRAM ;
reg [31:0] ReadData_MMIO ;

//----------------------------------------------------------------
// Data memory address decoding
//----------------------------------------------------------------
//assign dec_DROM		= (ALUResult >= DROM_BASE && ALUResult <= DROM_BASE+2**DROM_DEPTH_BITS-1) ? 1'b1 : 1'b0;
//The assignment above works too instead of the one below. Probably synthesizes to the same thing.
assign dec_DROM			= (ALUResult[31:DROM_DEPTH_BITS] == DROM_BASE[31:DROM_DEPTH_BITS]) ? 1'b1 : 1'b0;
assign dec_DRAM			= (ALUResult[31:DRAM_DEPTH_BITS] == DRAM_BASE[31:DRAM_DEPTH_BITS]) ? 1'b1 : 1'b0;
assign dec_LED			= (ALUResult == LED_ADDRESS) ? 1'b1 : 1'b0;
assign dec_DIP			= (ALUResult == DIP_ADDRESS) ? 1'b1 : 1'b0;
assign dec_PB 		   	= (ALUResult == PB_ADDRESS) ? 1'b1 : 1'b0;
assign dec_CONSOLE	   	= (ALUResult == CONSOLE_ADDRESS) ? 1'b1 : 1'b0;
assign dec_CONSOLE_IN_valid	= (ALUResult == CONSOLE_IN_valid_ADDRESS) ? 1'b1 : 1'b0;
assign dec_CONSOLE_OUT_ready= (ALUResult == CONSOLE_OUT_ready_ADDRESS) ? 1'b1 : 1'b0;
assign dec_SEVENSEG	    	= (ALUResult[31:2] == SEVENSEG_ADDRESS[31:2]) ? 1'b1 : 1'b0;
assign dec_MMIO         = dec_CONSOLE || dec_CONSOLE_IN_valid || dec_CONSOLE_OUT_ready || dec_PB || dec_DIP;

//----------------------------------------------------------------
// Input (into RV) multiplexing
//----------------------------------------------------------------
always@( * ) begin
if (dec_DROM_W)
	ReadData_in <= ReadData_DROM ; 
else if (dec_DRAM_W)
	ReadData_in <= ReadData_DRAM ;
else if (dec_MMIO_W)
	ReadData_in <= ReadData_MMIO ; 	
else
	ReadData_in <= 32'h0 ;
end

//----------------------------------------------------------------
// DRAM write
//----------------------------------------------------------------
localparam NUM_COL = 4;
localparam COL_WIDTH = 8;
integer i;
always@(posedge CLK) begin
	if( MemWrite_out[3] || MemWrite_out[2] || MemWrite_out[1] || MemWrite_out[0] ) begin
		for(i=0;i<NUM_COL;i=i+1) begin
			if(MemWrite_out[i]) begin
				if( dec_DRAM ) begin
					DRAM[ALUResult[DROM_DEPTH_BITS-1:2]][i*COL_WIDTH +: COL_WIDTH] <= WriteData_out[i*COL_WIDTH +: COL_WIDTH];
				end		      
			end
		end
	end
    // ReadData_DRAM <= DRAM[ALUResult[DRAM_DEPTH_BITS-1:2]] ; //Uncomment only if only using synch read for memory
end

//----------------------------------------------------------------
// Asych DRAM read - //Uncomment the following block (3 lines) if NOT using synch read for memory
//----------------------------------------------------------------
always@( * ) begin 
    ReadData_DRAM <= DRAM[ALUResult[DRAM_DEPTH_BITS-1:2]] ; // async read
end

//----------------------------------------------------------------
// IROM read
//----------------------------------------------------------------
always@( * ) begin // @posedge CLK only if using synch read for memory
    Instr = ( ( PC[31:IROM_DEPTH_BITS] == IROM_BASE[31:IROM_DEPTH_BITS]) && // To check if address is in the valid range
                (PC[1:0] == 2'b00) )? // and is word aligned - we do not support instruction sizes other than 32.
                 IROM[PC[IROM_DEPTH_BITS-1:2]] : 32'h00000013 ; // If the address is invalid, the instruction fetched is NOP. 
                 												// This can be changed to trigger an exception instead if need be.
end

//----------------------------------------------------------------
// DROM read
//----------------------------------------------------------------
always@( * ) begin // @posedge CLK only if using synch read for memory
    ReadData_DROM <= DROM[ALUResult[DROM_DEPTH_BITS-1:2]] ;
end

//----------------------------------------------------------------
// MMIO read
//----------------------------------------------------------------
always@( * ) begin // @posedge CLK only if using synch read for memory
if (dec_DIP)
	ReadData_MMIO <= { {31-N_DIPs+1{1'b0}}, DIP } ; 
else if (dec_PB)
	ReadData_MMIO <= { {31-N_PBs+1{1'b0}}, PB } ; 
else if (dec_CONSOLE && CONSOLE_IN_valid)
	ReadData_MMIO <= {24'b0, CONSOLE_IN};
else if (dec_CONSOLE_IN_valid)
	ReadData_MMIO <= {31'b0, CONSOLE_IN_valid};	
else if (dec_CONSOLE_OUT_ready)
	ReadData_MMIO <= {31'b0, CONSOLE_OUT_ready};		
else
	ReadData_MMIO <= 32'h0 ;
end

//----------------------------------------------------------------
// Delaying the decoded signals for multiplexing (delay only if using synch read for memory)
//----------------------------------------------------------------
always@( * ) begin // @posedge CLK only if using synch read for memory
    dec_DROM_W <= dec_DROM;
    dec_DRAM_W <= dec_DRAM;
    dec_MMIO_W <= dec_MMIO;
end

//----------------------------------------------------------------
// SevenSeg write
//----------------------------------------------------------------
integer j;
always@(posedge CLK) begin
	if( MemWrite_out[3] || MemWrite_out[2] || MemWrite_out[1] || MemWrite_out[0] ) begin
		for(j=0;j<NUM_COL;j=j+1) begin
			if(MemWrite_out[j]) begin
				if (RESET)
					SEVENSEGHEX <= 32'b0;
				else if (dec_SEVENSEG)
					SEVENSEGHEX[j*COL_WIDTH +: COL_WIDTH] <= WriteData_out[j*COL_WIDTH +: COL_WIDTH];		      
			end
		end
	end
end

//----------------------------------------------------------------
// Memory-mapped LED write
//----------------------------------------------------------------
always@(posedge CLK) begin
    if(RESET)
        LED_OUT <= 0 ;
    else if( MemWrite_out[0] && dec_LED ) 
        LED_OUT <= WriteData_out[N_LEDs_OUT-1 : 0] ;
end

//----------------------------------------------------------------
// Console read / write
//----------------------------------------------------------------
always @(posedge CLK) begin
	CONSOLE_OUT_valid <= 1'b0;
	CONSOLE_IN_ack <= 1'b0;
	if (MemWrite_out[0] && dec_CONSOLE && CONSOLE_OUT_ready)
	begin
		CONSOLE_OUT <= WriteData_out[7:0];
		CONSOLE_OUT_valid <= 1'b1;
	end
	if (MemRead && dec_CONSOLE && CONSOLE_IN_valid)
		CONSOLE_IN_ack <= 1'b1;
end
// Possible spurious CONSOLE_IN_ack and a lost character if we don't have a MemRead signal. 
// Alternatively, make sure ALUResult is never the address of UART other than when accessing it.
// Also, the character received from PC in the CLK cycle immediately following a character read by the processor is lost. 
// This is not that much of a problem in practice though.

//----------------------------------------------------------------
// Debug LEDs
//----------------------------------------------------------------
assign LED_PC = PC[15-N_LEDs_OUT+1 : 2]; // debug showing PC

//----------------------------------------------------------------
// RV port map
//----------------------------------------------------------------
RV RV1(
	CLK,
	RESET,
	Instr,
	ReadData_in,
	MemRead,
	MemWrite_out,
	PC,
	ALUResult,
	WriteData_out
);

endmodule