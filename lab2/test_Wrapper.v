`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
--	(c) Thao Nguyen and Rajesh Panicker
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/
module test_Wrapper #(
	   parameter N_LEDs_OUT	= 8,					
	   parameter N_DIPs		= 16,
	   parameter N_PBs		= 3 
	)
	(
	);
	
	// Signals for the Unit Under Test (UUT)
	reg  [N_DIPs-1:0] DIP = 0;		
	reg  [N_PBs-1:0] PB = 0;			
	wire [N_LEDs_OUT-1:0] LED_OUT;
	wire [6:0] LED_PC;			
	wire [31:0] SEVENSEGHEX;	
	wire [7:0] CONSOLE_OUT;
	reg  CONSOLE_OUT_ready = 0;
	wire CONSOLE_OUT_valid;
	reg  [7:0] CONSOLE_IN = 0;
	reg  CONSOLE_IN_valid = 0;
	wire CONSOLE_IN_ack;
	reg  RESET = 0;					
	reg  CLK = 0;				
	
	// Instantiate UUT
	Wrapper dut(DIP, PB, LED_OUT, LED_PC, SEVENSEGHEX, CONSOLE_OUT, CONSOLE_OUT_ready, CONSOLE_OUT_valid, CONSOLE_IN, CONSOLE_IN_valid, CONSOLE_IN_ack, RESET, CLK) ;
	
	// STIMULI
    initial
    begin
		RESET = 1; #10; RESET = 0; //hold reset state for 10 ns.
		CONSOLE_OUT_ready = 1'h1; // ok to keep it high continously in the testbench. In reality, it will be high only if UART is ready to send a data to PC
        CONSOLE_IN = 8'h50;// 'P'. Will be read and ignored by the processor
        CONSOLE_IN_valid = 1'h1;
        wait(CONSOLE_IN_ack);
        wait(~CONSOLE_IN_ack);
        CONSOLE_IN_valid = 1'h0;
        #105;
        CONSOLE_IN = 8'h41;// 'A'
        CONSOLE_IN_valid = 1'h1;
        wait(CONSOLE_IN_ack);
        wait(~CONSOLE_IN_ack);
		CONSOLE_IN_valid = 1'h0;
        #105;
        CONSOLE_IN = 8'h0D;// '\r'
        CONSOLE_IN_valid = 1'h1;
        wait(CONSOLE_IN_ack); // should print "Welcome to CG3207" following this.
        wait(~CONSOLE_IN_ack);
        CONSOLE_IN_valid = 1'h0;
		//insert rest of the stimuli here
    end
	
	// GENERATE CLOCK       
    always          
    begin
       #5 CLK = ~CLK ; // invert clk every 5 time units 
    end
    
endmodule
