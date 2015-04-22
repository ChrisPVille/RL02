`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:12:24 02/26/2015 
// Design Name: 
// Module Name:    headerDecode 
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

module headerDecode(
	input clk,
	input rst,
	input headerBitIn,
   input headerBitInStrobe,
   input [2:0] decode_state,
   output reg [5:0] sectorNum,
   output reg sectorNumReady,
   output reg headNum,
   output reg headNumReady,
   output reg [8:0] cylNum,
   output reg cylNumReady,
   output reg crcInvalid
   );
	
	reg [2:0] header_state;
	reg [3:0] bitCount;
	reg [15:0] onDiskCRC;
	
	reg crcReset;
	reg crcSampleNow;
	reg doCRCCompare;
	wire [15:0] computedCRC;
	
   crc crc16 (.clk(clk),
				.rst(crcReset),
				.data_in(headerBitIn),
				.crc_en(crcSampleNow),
				.crc_out(computedCRC));
	
	`include "FSMStates.v"
	 
	 // State encodings
	parameter [2:0]
	HDR_WAIT     = 3'b000, //Wait here until decode state is Header
	HDR_SECTOR	 = 3'b001, //Count out 6 Bits then v
	HDR_HEAD		 = 3'b010, //Count one bit then v
	HDR_CYL      = 3'b011, //count 9 bits then v
	HDR_RESERV   = 3'b100, //count 16 bits then v
	HDR_CRC      = 3'b101; //count 16 bits, do the compare then WAIT
	
	always @(posedge clk) begin
    if(rst) begin
      header_state <= HDR_WAIT;
		crcReset <= 1;
      bitCount <= 4'b0;
		sectorNum <= 6'b0;
      cylNum <= 9'b0;
		onDiskCRC <= 16'b0;
      sectorNumReady <= 0;
		cylNumReady <= 0;
      headNum <= 0;
		headNumReady <= 0;
		crcInvalid <= 0;
		doCRCCompare <= 0;
		crcSampleNow <= 0;
    end else begin
		crcReset <= 0;
		crcSampleNow <= 0;
      case (header_state)
        HDR_WAIT:
          if(decode_state == DSFM_HDR) begin
			 	headNumReady <= 0;
				cylNumReady <= 0;
				sectorNumReady <= 0;
            header_state <= HDR_SECTOR;
          end
        HDR_SECTOR:
          if(headerBitInStrobe) begin
				crcSampleNow <= 1;
			   bitCount <= bitCount + 1;
				sectorNum <= {headerBitIn, sectorNum[5:1]};
            if(bitCount >= 5) begin
              bitCount <= 4'b0;
              header_state <= HDR_HEAD;
            end
          end
        HDR_HEAD:
          begin
            if(headerBitInStrobe) begin
				  crcSampleNow <= 1;
				  headNum <= headerBitIn;
				  header_state <= HDR_CYL;
				end
			 end
        HDR_CYL:
		    begin
            if(headerBitInStrobe) begin
				  crcSampleNow <= 1;
			     bitCount <= bitCount + 1;
			  	  cylNum <= {headerBitIn, cylNum[8:1]};
              if(bitCount >= 8) begin
                bitCount <= 4'b0;
                header_state <= HDR_RESERV;
              end
            end
		    end
        HDR_RESERV:
          begin
            if(headerBitInStrobe) begin
				  crcSampleNow <= 1;
				  bitCount <= bitCount + 1;
				  if(bitCount >= 15) begin
				    bitCount <= 4'b0;
				    header_state <= HDR_CRC;
				  end
				end
			 end
        HDR_CRC: //TODO Make this check the CRC
          begin
				if(doCRCCompare) begin
					if(onDiskCRC != computedCRC) begin
						crcInvalid <= 1;
					end //TODO We're getting stuck, probably here.  Check FSM encoding options
					//else begin
						sectorNumReady <= 1;
						headNumReady <= 1;
						cylNumReady <= 1;
					//end
				   bitCount <= 4'b0;
					doCRCCompare <= 0;
				   header_state <= HDR_WAIT;
				end
				
				if(headerBitInStrobe) begin //TODO This could be an else if, but I don't think there is ever a case when the headerBitInStrobe will fire the cycle before exiting the state
				  bitCount <= bitCount + 1;
				  onDiskCRC <= {onDiskCRC[14:0], headerBitIn};
				  if(bitCount == 15) begin
					  doCRCCompare <= 1;
				  end
				end
			end
      endcase
    end
  end
endmodule
