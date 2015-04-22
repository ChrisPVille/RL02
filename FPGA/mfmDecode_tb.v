`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:51:00 02/21/2015
// Design Name:   mfmDecode
// Module Name:   C:/Users/ChrisP/Documents/RL02Controller/RL02Controller/mfmDecode_tb.v
// Project Name:  RL02Controller
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mfmDecode
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module mfmDecode_tb;

	// Inputs
	reg clk;
	reg rst;
	reg mfmIn;
	wire mfmEdge;

	// Outputs
	wire currentRealBit;
	wire currentRealBitValid;
	wire mfmSynced;

	//Edge detector is required for this test
	inputSync is (
	   .clk(clk),
		.rst(rst),
		.async_in(mfmIn),
		.sync_out(mfmSynced)
	);
	
	edgeDetect edgey (
		.clk(clk),
		.rst(rst),
		.data(mfmSynced),
		.strobe(mfmEdge)
	);
	
	// Instantiate the Unit Under Test (UUT)
	mfmDecode uut (
		.clk(clk), 
		.rst(rst), 
		.mfmIn(mfmSynced), 
		.mfmEdge(mfmEdge), 
		.currentRealBit(currentRealBit), 
		.currentRealBitValid(currentRealBitValid)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		mfmIn = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		rst = 1;
		toggle_clk;
		rst = 0;

		mfmIn = 0;
		toggle_clk;

		repeat (46) begin
		mfmIn=1;
		toggle_clk;
		mfmIn=0;
		toggle_clk;
		end

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		//INTENTIONAL ERROR!!!
		//mfmIn=1;
		//toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;

		mfmIn=1;
		toggle_clk;

		mfmIn=0;
		toggle_clk;
		  
		// Add stimulus here

	end
	
	task toggle_clk;
	begin
		#10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
      #10 clk = ~clk;
    end
	 endtask
      
endmodule

