`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Thao Nguyen and Rajesh Panicker  
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

//>>>>>>>>>>>> ******* FOR SIMULATION. DO NOT SYNTHESIZE THIS DIRECTLY (This is use as a component in TOP.vhd for Synthesis) ******* <<<<<<<<<<<<

module Wrapper
#(
	parameter N_LEDs_OUT      = 8,   // Number of LEDs displaying Result. LED(15 downto 15-N_LEDs_OUT+1). 8 by default
	parameter N_DIPs = 16,           // Number of DIPs. 16 by default
	parameter N_PBs  = 3             // Number of PushButtons. 3 by default
		                             // [2:0] -> BTNL, BTNC, BTNR. Note that BTNU is used as PAUSE and BTND is used as RESET
)
(
	input  [N_DIPs-1:0] DIP, 		 		// DIP switch inputs. Not debounced. Mapped to 0x00000C04. 
	                                        // Only the least significant 16 bits read from this location are valid. 
	input  [N_PBs-1:0] PB,  				// PB switch inputs. Not debounced.	Mapped to 0x00000C08. 
	                                        // Only the least significant 4 bits read from this location are valid. Order (3 downto 0) -> BTNU, BTNL, BTNR, BTND.
	output reg [N_LEDs_OUT-1:0] LED_OUT, 	// LED(15 downto 8) mapped to 0x00000C00. Only the least significant 8 bits written to this location are used.
	output [6:0] LED_PC, 					// LED(6 downto 0) showing PC(8 downto 2).
	output reg [31:0] SEVENSEGHEX, 			// 7 Seg LED Display. Mapped to 0x00000C18. The 32-bit value will appear as 8 Hex digits on the display.
	output reg [7:0] CONSOLE_OUT,           // CONSOLE (UART) Output. Mapped to 0x00000C0C. The least significant 8 bits written to this location are sent to PC via UART.
											// Check if CONSOLE_OUT_ready (0x00000C14) is set before writing to this location (especially if your CLK_DIV_BITS is small).
											// Consecutive STRs to this location not permitted (there should be at least 1 instruction gap between STRs to this location).
	input	CONSOLE_OUT_ready,				// An indication to the wrapper/processor that it is ok to write to the CONSOLE_OUT (UART hardware).
	                                        //  This bit should be set in the testbench to indicate that it is ok to write a new character to CONSOLE_OUT from your program.
	                                        //  It can be read from the address 0x00000C14.
	output reg CONSOLE_OUT_valid,           // An indication to the UART hardware that the processor has written a new data byte to be transmitted.
	input  [7:0] CONSOLE_IN,                // CONSOLE (UART) Input. Mapped to 0x00000C0C. The least significant 8 bits read from this location is the character received from PC via UART.
	                                        // Check if CONSOLE_IN_valid flag (0x00000C10)is set before reading from this location.
											// Consecutive LDRs from this location not permitted (needs at least 1 instruction spacing between LDRs).
											// Also, note that there is no Tx FIFO implemented. DO NOT send characters from PC at a rate faster than 
											//  your processor (program) can read them. This means sending only 1 char every few seconds if your CLK_DIV_BITS is 26.
											// 	This is not a problem if your processor runs at a high speed.
	input  	CONSOLE_IN_valid,               // An indication to the wrapper/processor that there is a new data byte waiting to be read from the UART hardware.
	                                        // This bit should be set in the testbench to indicate a new character (Else, the processor will only read in 0x00).
											//  It can be read from the address 0x00000C10.
	output reg CONSOLE_IN_ack,              // An indication to the UART hardware that the processor has read the newly received data byte.
	                                        // The testbench should clear CONSOLE_IN_valid when this is set.
	input  RESET,							// Active high. Implemented in TOP as not(CPU_RESET) or Internal_reset (CPU_RESET is red push button and is active low).
	input  CLK								// Divided Clock from TOP.
);                                             

//----------------------------------------------------------------
// RV signals
//----------------------------------------------------------------
wire[31:0] PC ;
wire[31:0] Instr ;
reg[31:0] ReadData ;
wire MemRead ;
wire MemWrite ;
wire[31:0] ALUResult ;
wire[31:0] WriteData ;

//----------------------------------------------------------------
// Address Decode signals
//---------------------------------------------------------------
wire dec_DATA_CONST, dec_DATA_VAR, dec_LED, dec_DIP, dec_CONSOLE, dec_PB, dec_7SEG, dec_CONSOLE_IN_valid, dec_CONSOLE_OUT_ready;  // 'enable' signals from data memory address decoding

//----------------------------------------------------------------
// Memory declaration
//-----------------------------------------------------------------
reg [31:0] INSTR_MEM		[0:127]; // instruction memory
reg [31:0] DATA_CONST_MEM	[0:127]; // data (constant) memory
reg [31:0] DATA_VAR_MEM     [0:127]; // data (variable) memory


//----------------------------------------------------------------
// Instruction Memory
//----------------------------------------------------------------
initial begin

		// todo: instruction memory goes here. e.g.:INSTR_MEM[0] = 32'hxxxxxxxx;
end

//----------------------------------------------------------------
// Data (Constant) Memory
//----------------------------------------------------------------
initial begin

		// todo: instruction memory goes here. e.g.:DATA_CONST_MEM[0] = 32'hxxxxxxxx;
end


//----------------------------------------------------------------
// Data (Variable) Memory
//----------------------------------------------------------------
initial begin
end

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
	ReadData,
	MemRead,
	MemWrite,
	PC,
	ALUResult,
	WriteData
);

//----------------------------------------------------------------
// Data memory address decoding
//----------------------------------------------------------------
assign dec_DATA_CONST		= (ALUResult >= 32'h00002000 && ALUResult <= 32'h000021FC) ? 1'b1 : 1'b0;
assign dec_DATA_VAR			= (ALUResult >= 32'h00002200 && ALUResult <= 32'h000023FC) ? 1'b1 : 1'b0;
assign dec_LED				= (ALUResult == 32'h00002400) ? 1'b1 : 1'b0;
assign dec_DIP				= (ALUResult == 32'h00002404) ? 1'b1 : 1'b0;
assign dec_PB 		   		= (ALUResult == 32'h00002408) ? 1'b1 : 1'b0;
assign dec_CONSOLE	   		= (ALUResult == 32'h0000240C) ? 1'b1 : 1'b0;
assign dec_CONSOLE_IN_valid	= (ALUResult == 32'h00002410) ? 1'b1 : 1'b0;
assign dec_CONSOLE_OUT_ready= (ALUResult == 32'h00002414) ? 1'b1 : 1'b0;
assign dec_7SEG	    		= (ALUResult == 32'h00002418) ? 1'b1 : 1'b0;

//----------------------------------------------------------------
// Data memory read
//----------------------------------------------------------------
always@( * ) begin
if (dec_DIP)
	ReadData <= { {31-N_DIPs+1{1'b0}}, DIP } ; 
else if (dec_PB)
	ReadData <= { {31-N_PBs+1{1'b0}}, PB } ; 
else if (dec_DATA_VAR)
	ReadData <= DATA_VAR_MEM[ALUResult[8:2]] ; 
else if (dec_DATA_CONST)
	ReadData <= DATA_CONST_MEM[ALUResult[8:2]] ; 
else if (dec_CONSOLE && CONSOLE_IN_valid)
	ReadData <= {24'b0, CONSOLE_IN};
else if (dec_CONSOLE_IN_valid)
	ReadData <= {31'b0, CONSOLE_IN_valid};	
else if (dec_CONSOLE_OUT_ready)
	ReadData <= {31'b0, CONSOLE_OUT_ready};		
else
	ReadData <= 32'h0 ; 
end
			
//----------------------------------------------------------------
// Instruction memory read
//----------------------------------------------------------------
assign Instr = ( (PC >= 32'h00000000) && (PC <= 32'h000001FC) ) ? // To check if address is in the valid range, assuming 128 word memory. Also helps minimize warnings
                 INSTR_MEM[PC[8:2]] : 32'h00000000 ; 

//----------------------------------------------------------------
// Console read / write
//----------------------------------------------------------------
always @(posedge CLK) begin
	CONSOLE_OUT_valid <= 1'b0;
	CONSOLE_IN_ack <= 1'b0;
	if (MemWrite && dec_CONSOLE && CONSOLE_OUT_ready)
	begin
		CONSOLE_OUT <= WriteData[7:0];
		CONSOLE_OUT_valid <= 1'b1;
	end
	if (MemRead && dec_CONSOLE && CONSOLE_IN_valid)
		CONSOLE_IN_ack <= 1'b1;
end
// Possible spurious CONSOLE_IN_ack and a lost character if we don't have a MemRead signal. ALternatively, make sure ALUResult is never the address of UART other than when accessing it.
// Also, the character received from PC in the CLK cycle immediately following a character read by the processor is lost. This is not that much of a problem in practice though.

//----------------------------------------------------------------
// Data Memory-mapped LED write
//----------------------------------------------------------------
always@(posedge CLK) begin
    if(RESET)
        LED_OUT <= 0 ;
    else if( MemWrite && dec_LED ) 
        LED_OUT <= WriteData[N_LEDs_OUT-1 : 0] ;
end

//----------------------------------------------------------------
// SevenSeg LED Display write
//----------------------------------------------------------------
always @(posedge CLK) begin
	if (RESET)
		SEVENSEGHEX <= 32'b0;
	else if (MemWrite && dec_7SEG)
		SEVENSEGHEX <= WriteData;
end

//----------------------------------------------------------------
// Data Memory write
//----------------------------------------------------------------
always@(posedge CLK) begin
    if( MemWrite && dec_DATA_VAR ) 
        DATA_VAR_MEM[ALUResult[8:2]] <= WriteData ;
end

endmodule
