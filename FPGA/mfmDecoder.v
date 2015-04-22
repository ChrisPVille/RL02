`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:38:16 02/21/2015 
// Design Name: 
// Module Name:    mfmDecoder 
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
 
module mfmDecode(clk, rst, mfmIn, mfmEdge, skipMFMBit, currentRealBit, currentRealBitValid);
  input  clk; //Reception Clock (approximately 61.2us period) 65.536Mhz
  input  rst; //Positive Synchronous Reset
  input  mfmIn; //mfm encoded, self clocking data stream from RL-02
  input  mfmEdge; //Positive input on changing edge of MFM data
  input  skipMFMBit; //There are bit patterns (the header is one of them) that can appear valid when we're actually fenceposted (off by one). Only the FSM can know if this has occured (before it's an error)
  output reg currentRealBit;
  output reg currentRealBitValid;
  
  reg [2:0] mfmTimer; //DPLL counter
  reg firstEdgeDetected;
  reg currentMFMBitValid;//Flag that currentMFMBit holds valid sampled data
  reg updateRealBit;
  reg localSkipMFMBit;
  reg skipOutputLoop;
  
  reg [3:0] prevMFMBits;
  
  always @(posedge clk) begin //DPLL sampling thingy
    if(rst) begin
      mfmTimer <= 4'b0;
      firstEdgeDetected <= 0;
      currentMFMBitValid <= 0;
    end else begin
      currentMFMBitValid <= 0;
      if(mfmEdge) begin//If there's a data transition
        mfmTimer <= 4'b0;//Reset the DPLL
        firstEdgeDetected <= 1;
      end else begin//If we're free running
        if(firstEdgeDetected) begin
          mfmTimer <= mfmTimer + 1'b1;
			 if(mfmTimer == 2) begin //if it is time to sample
            currentMFMBitValid <= 1;
          end
        end
      end
    end
  end
  
  always @(posedge clk) begin
    if(rst) begin
      currentRealBit <= 0;
      currentRealBitValid <= 0;
		prevMFMBits <= 4'b0;
		updateRealBit <= 0;
		localSkipMFMBit <= 0;
		skipOutputLoop <= 0;
    end else begin
      
		currentRealBitValid <= 0;
		updateRealBit <= 0;
		
		if(skipMFMBit) begin
		  localSkipMFMBit <= 1;
		end

      if(currentMFMBitValid) begin
        prevMFMBits <= {prevMFMBits[2:0], mfmIn};
		  updateRealBit <= updateRealBit + 1;
	   end
		
		if(updateRealBit) begin
		  if(localSkipMFMBit) begin
		    localSkipMFMBit <= 0;
		  end else if(skipOutputLoop) begin
		     skipOutputLoop <= 0;
		  end else begin
		     skipOutputLoop <= 1;
			  casez (prevMFMBits)

				 4'b0100,4'bz010: begin
					currentRealBit <= 0; 
					currentRealBitValid <= 1;
				 end
				
				 4'bzz01: begin
					currentRealBit <= 1;
					currentRealBitValid <= 1;
				 end
				 
				 default: begin
					$display("MFM ERROR"); //TODO Maybe add error flag to report up the problem (likely this will be a Fail the sector unless special mode is enabled) (note: will need some sort of holdoff if doing this for the initial deocde)
				 end

			  endcase
			end
		end		
    end
  end

endmodule