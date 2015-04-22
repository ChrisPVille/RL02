`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:57:36 02/22/2015
// Design Name:   decodeFSM
// Module Name:   C:/Users/ChrisP/Documents/RL02Controller/RL02Controller/decodeFSM_tb.v
// Project Name:  RL02Controller
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: decodeFSM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module decodeFSM_tb;

	// Inputs
	reg clk;
	reg rst;
	reg sectorPulse;
   reg currentRealBit;
	reg currentRealBitValid;

	// Outputs
	wire [15:0] bitOut;
	wire bitOutReady;
	wire headerOut;
	wire headerOutStrobe;
	wire [2:0] decode_state;
	
	wire [5:0] sectorNum;
   wire sectorNumReady;
   wire headNum;
   wire headNumReady;
   wire [8:0] cylNum;
   wire cylNumReady;
   wire crcInvalid;
	wire SPI_FIFOAcceptingData;
	reg readBack;


	// Instantiate the Unit Under Test (UUT)
	decodeFSM uut (
		.clk(clk), 
		.rst(rst), 
		.currentRealBit(currentRealBit), 
		.currentRealBitValid(currentRealBitValid), 
		.sectorPulse(sectorPulse), 
		.wordOut(bitOut), 
		.wordOutReady(bitOutReady), 
		.headerOut(headerOut), 
		.headerOutStrobe(headerOutStrobe),
		.decode_state(decode_state),
		.prog_empty(SPI_FIFOAcceptingData)
	);
	
	headerDecode HDR (
		.clk(clk),
		.rst(rst),
		.headerBitIn(headerOut),
		.headerBitInStrobe(headerOutStrobe),
		.decode_state(decode_state),
		.sectorNum(sectorNum),
		.sectorNumReady(sectorNumReady),
		.headNum(headNum),
		.headNumReady(headNumReady),
		.cylNum(cylNum),
		.cylNumReady(cylNumReady),
		.crcInvalid(crcInvalid)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		currentRealBit = 0;
		currentRealBitValid = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		rst = 1;
		sectorPulse = 1;
		toggle_clk;
		rst = 0;
		
		zero;
		
		sectorPulse = 0;

		repeat (46) begin //Preamble
		zero;
		end
		one; //Sync Bit
		
		zero;//Sector
		zero;
		one;
		zero;
		zero;
		one;
		
		zero;//head
		
		zero;//Cyninder
		zero;
		zero;
		zero;
		zero;
		zero;
		zero;
		zero;
		zero;
		
		repeat (16) begin
		  zero;//Reserved word
		end
		
		zero;//CRC-16 of previous 2 words
		one;
		zero;
		one;
		
		zero;
		zero;
		zero;
		zero;
		
		zero;
		zero;
		zero;
		zero;
		
		one;
		one;
		one;
		one;
		
		//postamble
		repeat (16) begin
		  zero;
		end
		
		one; //random glitch (to be expected between post and pre-ambles

		//data preamble
		repeat (46) begin
		  zero;
		end
		one;//sync
		
		readBack = 1;
		repeat (100) begin
			toggle_clk;
		end
		readBack = 0;
		
	   //data;
		repeat (1024) begin
		  one;
		  zero;
		end
		repeat (16) begin //Data CRC
			one; //TODO figure out what CRC is required (although the FPGA shouldn't care at all)
		end
		
			
		
		//postamble
		repeat (16) begin
		  zero;
		end
		
		one;//Random glitches from previous records (as observed on disk, should be ignored)
		zero;
		zero;
		one;
		one;
		one;
		one;
		one;
		zero;
		
		sectorPulse = 1;
		repeat (24) begin//Let the sector pulse sit for a while
		  toggle_clk;
		end;
		
		repeat (10) begin //There are some drive utilized things that fly by during the sector pulse
		  one;
		  zero;
		end
		
		sectorPulse = 0;
		
		repeat (46) begin //Preamble
		  zero;
		end
		one; //Sync Bit
		
		zero;
		zero;

	end
	
	task one;
	begin
	   currentRealBit = 1;
		currentRealBitValid = 1;
		#10 clk = ~clk;
      #10 clk = ~clk;
		currentRealBitValid = 0;
		toggle_clk;
	end
	endtask
		
   task zero;
	begin
	   currentRealBit = 0;
		currentRealBitValid = 1;
		#10 clk = ~clk;
      #10 clk = ~clk;
		currentRealBitValid = 0;
		toggle_clk;
	end
	endtask
	
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

    end
	 endtask
      
endmodule

