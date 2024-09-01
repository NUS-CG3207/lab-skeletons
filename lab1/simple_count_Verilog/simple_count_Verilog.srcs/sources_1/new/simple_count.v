`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.08.2016 17:48:49
// Design Name: 
// Module Name: simple_count
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module simple_count(
    input clk,
    input enable,
    output [3:0] led
    );
    
    reg [29:0] count = 0 ;
    
    always@( posedge clk )
    begin
        if( ~enable )
            count <= count + 1 ;
    end    
    
    assign led = count[29:26] ;
    
endmodule



