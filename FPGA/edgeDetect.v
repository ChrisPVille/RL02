`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:37:28 02/21/2015 
// Design Name: 
// Module Name:    edgeDetect 
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

module edgeDetect(clk, rst, data, strobe);
  input clk;
  input rst;
  input data;
  output strobe;
  
  reg prevData;
  reg strobe;
  
  always @(posedge clk) begin
    if(rst) begin
      prevData <= 0;
    end else begin
      prevData <= data;
    end    
  end
  
  always @(posedge clk) begin
	 if(rst) begin
	   strobe <= 0;
	 end else begin
	   strobe <= data ^ prevData;
	 end
  end
  
endmodule
  