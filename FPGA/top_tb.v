// Verilog test fixture created from schematic C:\Users\ChrisP\Documents\RL02Controller\RL02Controller\top_sch.sch - Tue Feb 24 22:11:27 2015

`timescale 1ns / 1ps

module top_sch_top_sch_sch_tb();

// Inputs
   reg clk;
   reg rst;
   reg mfmIn;
   reg sector_in;

// Bidirs

// Instantiate the UUT
   top_sch UUT (
		.clk_in(clk), 
		.rst_in(rst), 
		.Drive_mfm_in(mfmIn), 
		.Drive_sector_in(sector_in)
   );
// Initialize Inputs

     	initial begin
		// Initialize Inputs
		clk = 0;
		mfmIn = 0;
		sector_in = 1;

		// Wait 100 ns for global reset to finish
		#100;
		
		rst = 1;
		toggle_clk;
		rst = 0;

		mfmIn = 0;
		toggle_clk;
		sector_in = 0;

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
