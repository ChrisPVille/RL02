`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:31:20 02/21/2015 
// Design Name: 
// Module Name:    DecodeFSM 
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

//TODO Add reset module that keeps almost everything (except the output clock) in reset until the sector pulses are detected (on speed)
 
module decodeFSM(clk, rst, currentRealBit, currentRealBitValid, sectorPulse, prog_empty, wordOut, wordOutReady, skipMFMBit, headerOut, headerOutStrobe, decode_state, beginWriteNow);
  `include "FSMStates.v"
  input  clk; //Reception Clock (approximately 30.6us period) 65.536Mhz*2
  input  rst; //Positive Synchronous Reset
  input  currentRealBit;
  input  currentRealBitValid;
  input  sectorPulse;
  input  prog_empty;
  output reg [16:0] wordOut; //Header+Data output
  output reg wordOutReady; //Strobes when header/data word is ready
  output reg skipMFMBit;
  output reg headerOut;
  output reg headerOutStrobe;
  output reg [2:0] decode_state;
  output reg beginWriteNow;
  
  reg [11:0] bitCounter;
  reg [5:0] headerbitCounter;
  reg [5:0] preamblebitCounter;

  
  always @(posedge clk) begin
    if(rst | sectorPulse) begin
		if(sectorPulse) begin
			decode_state <= DSFM_PR1;
		end else begin
			decode_state <= DSFM_INIT;
		end
      bitCounter <= 12'b0;
		preamblebitCounter <= 6'b0;
      wordOut <= 17'b0;
      headerOut <= 0;
		headerOutStrobe <= 0;
		headerbitCounter <= 0;
      wordOutReady <= 0;
		skipMFMBit <= 0;
		beginWriteNow <= 0;
    end else begin
		skipMFMBit <= 0;
      case (decode_state)
		  DSFM_INIT://Wait for the sector pulse
		  begin
		  end
		  
        DSFM_PR1:
          if(currentRealBitValid) begin
			   if(preamblebitCounter == 31) begin //Check the data right before we're about to start using it, if it looks inverted, fix it
				  if(currentRealBit == 1) begin
				    skipMFMBit <= 1;
				  end
				end
            if(preamblebitCounter < 32) begin
              preamblebitCounter <= preamblebitCounter + 1'b1; //hold off for a little bit
				end else if(currentRealBit == 1) begin //now, wait for the sync bit
              preamblebitCounter <= 6'b0;
				  if(!prog_empty) begin //If there's no room in the FPGA->Computer FIFO
                decode_state <= DSFM_PO2;//Skip this sector
				  end else begin
                decode_state <= DSFM_HDR;
				  end
            end
          end
        DSFM_HDR:
          begin
            wordOutReady <= 0;
				headerOutStrobe <= 0;
            
            if(headerbitCounter < 6'd48) begin 
              if(currentRealBitValid) begin
                headerbitCounter <= headerbitCounter + 1'b1;
					 headerOut <= currentRealBit;
					 headerOutStrobe <= 1;
					 wordOut <= {1'b0, currentRealBit, wordOut[15:1]};
					 if(headerbitCounter == 6'b001111) begin
						wordOut <= {1'b1, currentRealBit, wordOut[15:1]};
					 end
					 if((headerbitCounter & 4'b1111) == 4'b1111) begin
						wordOutReady <= 1;
					 end
              end 
            end else begin
              headerbitCounter <= 6'b0;
              decode_state <= DSFM_PO1;
            end
            
          end
        DSFM_PO1: //TODO Be careful with the last bit, as after 16, there might be nothing to enter the for loop with. May need to exit on 15th bit and let the idle counter below handle a small delay
		  begin
		  	if(currentRealBitValid) begin
				if(headerbitCounter < 16) begin 
					headerbitCounter <= headerbitCounter + 1'b1;
            end else begin
					headerbitCounter <= 6'b0;
               beginWriteNow <= 1;
					decode_state <= DSFM_IT_IDLE;
				end
			end
		  end
        DSFM_IT_IDLE: //TODO Check the timing and make sure we don't smash everything
		  begin
				beginWriteNow <= 0;
            decode_state <= DSFM_PR2;
		  end
        DSFM_PR2:
          if(currentRealBitValid) begin
				if(preamblebitCounter == 31) begin //Check the data right before we're about to start using it, if it looks inverted, fix it
				  if(currentRealBit == 1) begin
				    skipMFMBit <= 1;
				  end
				end
            if(preamblebitCounter < 32) begin
              preamblebitCounter <= preamblebitCounter + 1'b1; //hold off for a little bit
            end else if(currentRealBit == 1) begin //now, wait for the sync bit
              preamblebitCounter <= 6'b0;
				  decode_state <= DSFM_DATA;
            end
          end
        DSFM_DATA:				
          begin
			   wordOutReady <= 0;
				if(bitCounter < 12'd2064) begin
					if(currentRealBitValid) begin//This does require the first bit of the postable in order to exit this state
						bitCounter <= bitCounter + 1'b1;
						wordOut <= {1'b0, currentRealBit, wordOut[15:1]};
						if((bitCounter & 4'b1111) == 4'b1111) begin //Tools don't support mod for some reason
							wordOutReady <= 1;
						end
					end
				end else begin
				  bitCounter <= 12'b0;
				  decode_state <= DSFM_PO2;
				end
          end
        DSFM_PO2: //hold here until sector pulse
          begin
          end
      endcase
    end
  end

endmodule