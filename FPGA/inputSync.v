`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:03:51 02/24/2015 
// Design Name: 
// Module Name:    inputSync 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module inputSync(
    input clk,
	 input rst,
    input async_in,
    output sync_out
    );
	 
	 (* ASYNC_REG="TRUE" *) reg [1:0] sync;
	 
	 always@(posedge clk) begin
	   if(rst) begin
		  sync <= 2'b0;
		end else begin
		  sync <= {sync[0], async_in};
		end
    end
	 
	 assign sync_out = sync[1];
	 
endmodule
