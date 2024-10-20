`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: Shifter
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: RISC-V Processor Shifter Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Interface and implementation can be modified.
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

module Shifter(
    input [1:0] Sh,
    input [4:0] Shamt5,
    input [31:0] ShIn,
    output [31:0] ShOut
    );
      
    wire [31:0] ShTemp0 ;
    wire [31:0] ShTemp1 ;
    wire [31:0] ShTemp2 ;
    wire [31:0] ShTemp3 ;
    wire [31:0] ShTemp4 ;
                    
    assign ShTemp0 = ShIn ;
    shiftByNPowerOf2#(0) shiftBy0PowerOf2( Sh, Shamt5[0], ShTemp0, ShTemp1 ) ;
    shiftByNPowerOf2#(1) shiftBy1PowerOf2( Sh, Shamt5[1], ShTemp1, ShTemp2 ) ;
    shiftByNPowerOf2#(2) shiftBy2PowerOf2( Sh, Shamt5[2], ShTemp2, ShTemp3 ) ;
    shiftByNPowerOf2#(3) shiftBy3PowerOf2( Sh, Shamt5[3], ShTemp3, ShTemp4 ) ;
    shiftByNPowerOf2#(4) shiftBy4PowerOf2( Sh, Shamt5[4], ShTemp4, ShOut ) ;

	
endmodule


module shiftByNPowerOf2
//module Shifter
    #(parameter i = 0) // exponent
    (   
        input [1:0] Sh,
        input flagShift,
        input [31:0] ShTempIn,
        output reg [31:0] ShTempOut
    ) ;
    
    always@(Sh, ShTempIn, flagShift) begin
        if(flagShift)
            case(Sh)
                2'b00: ShTempOut = { ShTempIn[31-2**i:0], {2**i{1'b0}} } ;      	// SLL
                2'b10: ShTempOut = { {2**i{1'b0}}, ShTempIn[31:2**i] } ;        	// SRL    
                2'b11: ShTempOut = { {2**i{ShTempIn[31]}}, ShTempIn[31:2**i] } ;	// SRA
                //2'b01: ShTempOut = { ShTempIn[2**i-1:0], ShTempIn[31:2**i] } ;  	// ROR is not supported by RISC-V
                default: ShTempOut = ShTempIn; // invalid
            endcase   
        else
            ShTempOut = ShTempIn ;
    end
    
endmodule 
