`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:13:07 03/02/2015 
// Design Name: 
// Module Name:    drivePositioner 
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
module driveControl(
    input clk,
    input rst,
    input [15:0] SPICommandWord,
    input SPIFIFOEmpty,
    input sector_pulse,
	 input [5:0] sectorNumIn,
    input [8:0] cylNumIn,
    input sectorNumInReady,
	 input cylNumInReady,
    input headNumIn,
	 input headNumInReady,
	 input drive_ready,
	 input beginWriteNow,
	 input SPIProgFull,
	 output reg FIFOReadEnable,
    output reg inhibit_read,
    output reg writeData,
    output reg writeGate,
    output reg drive_command,
	 output drive_clock
    );
	
	reg [3:0] cnc_state;
	reg [15:0] SPICommandWordLocal;
	reg [3:0] curSPIBit;
	
	reg [15:0] driveCommandWord;
	reg [4:0] driveCommandWordCount;
	reg driveCommandInProgress;
	reg [3:0] clockDivider;
	reg drive_clock_FallingEdgeJustHappened;
	reg [3:0] writeDataPipeline;
	reg [8:0] SPIWriteWordCounter;
	
	reg [5:0] desiredSector;

	reg [15:0] compensatedWriteDataToDrive;
	reg [3:0] compensatedWriteDataToDriveCount;
	
	reg [3:0] return_state;
	
	parameter [3:0]
		CNC_INIT						= 4'b0000, //Initialize the drive
		CNC_IDLE     				= 4'b0001, //Wait here until we recieve an instruction
		CNC_DECODE	 				= 4'b0010, //Instruction Decode
		CNC_SEEK_CMD_SETUP		= 4'b0011, //Prepare the command to move the drive
		CNC_CMD_SECTORWAIT		= 4'b0100, //Wait for the sector pulse
		CNC_CMD_EXECUTE	 		= 4'b0101, //Issue the command to seek
		CNC_SEEK_WAIT				= 4'b0110, //Wait for drive ready
		CNC_WRITE_SETUP			= 4'b0111, //Gather the sector requested from the drive and prep the write queue
		CNC_WRITE_SYNC				= 4'b1000, //Wait for the FIFO to fill enough, then wait for our sector number to come up
		CNC_WRITE_EXECUTE			= 4'b1001; //Execute the write bits

	assign drive_clock = clockDivider[3];
	
	always @(posedge clk) begin
		if(rst) begin
			clockDivider <= 0;
			drive_clock_FallingEdgeJustHappened <= 0;
		end else begin
			clockDivider <= clockDivider + 1;
			if(clockDivider == 0) begin
				drive_clock_FallingEdgeJustHappened <= 1;
			end else begin
				drive_clock_FallingEdgeJustHappened <= 0;
			end
		end
	end
	
	always @(posedge clk) begin
		if(rst) begin
			cnc_state <= CNC_INIT;
			return_state <= CNC_IDLE;
			FIFOReadEnable <= 0;
			SPICommandWordLocal <= 16'b0;
			driveCommandWord <= 16'b0;
			driveCommandWordCount <= 5'b0;
			driveCommandInProgress <= 0;
			writeData <= 0;
			compensatedWriteDataToDriveCount <= 4'b0;
			compensatedWriteDataToDrive <= 16'b1111111111111111;
			writeDataPipeline <= 4'b0;
			desiredSector <= 6'b0;
			SPIWriteWordCounter <= 8'b0;
			curSPIBit <= 4'b0;
			writeGate <= 0;
			drive_command <= 0;
			inhibit_read <= 0;
		end else begin
			FIFOReadEnable <= 0;
			case (cnc_state)
				CNC_INIT:
				begin
					if(drive_ready) begin
						driveCommandWord[3] <= 1; //Drive Reset
						driveCommandWord[1] <= 0; //Get Status
						driveCommandWord[0] <= 1; //Sync Bit
						return_state <= CNC_IDLE;
						cnc_state <= CNC_CMD_SECTORWAIT;
					end
				end
				
				CNC_IDLE:
				begin					
					if(~SPIFIFOEmpty) begin
						SPICommandWordLocal <= SPICommandWord;
						cnc_state <= CNC_DECODE;
						FIFOReadEnable <= 1;
					end
				end
				
				CNC_DECODE:
				begin
				//NOTE Pipeline this if necessary
					cnc_state <= CNC_IDLE;
										
					case (SPICommandWordLocal[15:13]) 
					 
						3'b001: 
						begin
							cnc_state <= CNC_SEEK_CMD_SETUP;
						end
						
						3'b010:
						begin
							cnc_state <= CNC_WRITE_SETUP;
						end
					
					endcase
				end
				
				CNC_SEEK_CMD_SETUP:
				begin
					inhibit_read <= 1;
					return_state <= CNC_SEEK_WAIT;
					cnc_state <= CNC_CMD_SECTORWAIT;//Let's assume we will need to seek
					driveCommandWord[4] <= SPICommandWordLocal[10];//Pack the head number
					driveCommandWord[3] <= 0; //Drive Reset
					driveCommandWord[1] <= 0; //Get Status
					driveCommandWord[0] <= 1; //Sync Bit
					
					driveCommandWord[2] <= SPICommandWordLocal[9]; //travel direction
					driveCommandWord[15:7] <= SPICommandWordLocal[8:0];//Track delta
				end
				
				CNC_CMD_SECTORWAIT:
				begin
					if(sector_pulse) begin
						cnc_state <= CNC_CMD_EXECUTE;
					end
				end
				
				CNC_CMD_EXECUTE:
				begin
					if(~sector_pulse | driveCommandInProgress) begin
						driveCommandInProgress <= 1;
						if(drive_clock_FallingEdgeJustHappened) begin
							if(driveCommandWordCount < 16) begin //Setup the command word so the drive sees it on the next rising edge of the drive clock
								driveCommandWordCount <= driveCommandWordCount + 1;
								drive_command <= driveCommandWord[0];
								driveCommandWord <= {1'b0, driveCommandWord[15:1]};
							end else begin
								drive_command <= 0;
								driveCommandWordCount <= 5'b0;
								driveCommandWord <= 16'b0;
								driveCommandInProgress <= 0;
								cnc_state <= return_state; //We've shifted out the word, wait for the drive
							end
						end
					end
				end
				
				CNC_SEEK_WAIT:
				begin
					if(drive_ready & sector_pulse) begin
							cnc_state <= CNC_IDLE;
							inhibit_read <= 0;
					end
				end
				
				CNC_WRITE_SETUP: //Gather the sector requested from the drive and prep the write queue
				begin					
					if(~SPIFIFOEmpty) begin
						desiredSector <= SPICommandWord[5:0];
						FIFOReadEnable <= 1;
						cnc_state <= CNC_WRITE_SYNC;
					end
				end
				
				CNC_WRITE_SYNC: //Wait for the FIFO to fill enough, then wait for our sector number to come up
				begin //What an ugly combinatorial path... Some of this can be pipelined if it's necessary
					FIFOReadEnable <= 0;//
					if(SPIProgFull) begin //Fist off, make sure we have a full set of data to write
						if(sectorNumInReady) begin //If the sector number from the header decoder is valid now
							if(desiredSector == sectorNumIn) begin //If we've found the winning number
								if(beginWriteNow) begin //Showtime!
									inhibit_read <= 1;
									cnc_state <= CNC_WRITE_EXECUTE;
								end
							end
						end
					end
				end
				
				//TODO This needs to be simulated
				//TODO Also, CRC is probably failing at some point
				CNC_WRITE_EXECUTE: //Execute the write bits
				begin
					FIFOReadEnable <= 0;
					writeGate <= 1;
					if(curSPIBit == 15) begin
						FIFOReadEnable <= 1;//We are going to be reading from the FIFO next clock
					end
					
					compensatedWriteDataToDriveCount <= compensatedWriteDataToDriveCount + 1;
					writeData <= compensatedWriteDataToDrive[15];
					
					if(compensatedWriteDataToDriveCount == 0) begin
						SPIWriteWordCounter <= SPIWriteWordCounter + 1;
						writeDataPipeline <= {writeDataPipeline[2:0], SPICommandWord[curSPIBit]};
						curSPIBit <= curSPIBit + 1;
						casez (writeDataPipeline)//Bits [3] and [2] were previously written, bit [1] is the current bit to write and bit [0] is the next bit
							//The [1] bit is expanded to the full 65MHz clock time via compensatedWriteDataToDrive to simplify writing and accomplish peak shifting (see RL-02 tech guide)
							4'b0000:
								if(SPICommandWord[curSPIBit]) begin //If our next bit is a one
									compensatedWriteDataToDrive <= 16'b0000111111111110;//0111 (becomes 10) with Write Early
								end else begin
									compensatedWriteDataToDrive <= 16'b0000111111111111;//0111 (becomes 10)
								end
							4'b0001:
								compensatedWriteDataToDrive <= 16'b0000111111111111;//0111 (becomes 10) (NOTE: This is a data pattern requiring shifting, but we accomplish it via the 0000 and 1000 conditionals because you can't go back in time (not even you DEC)
							4'bz010:
								compensatedWriteDataToDrive <= 16'b1111111100001111;//1101 (becomes 01)
							4'bz011:
								compensatedWriteDataToDrive <= 16'b1111111110000111;//1101 (becomes 01) with Write Late
							4'bz10z:
								compensatedWriteDataToDrive <= 16'b1111111111111111;//1111 (becomes 00)
							4'bz110:
								compensatedWriteDataToDrive <= 16'b1111111000011111;//1101 (becomes 01) with Write Early
							4'bz111:
								compensatedWriteDataToDrive <= 16'b1111111100001111;//1101 (becomes 01)
							4'b1000:
								if(SPICommandWord[curSPIBit]) begin //If our next bit is a one
									compensatedWriteDataToDrive <= 16'b1000011111111110;//0111 (becomes 10) with Write Late and Write Early
								end else begin
									compensatedWriteDataToDrive <= 16'b1000011111111111;//0111 (becomes 10) with Write Late
								end
							4'b1001:
								compensatedWriteDataToDrive <= 16'b0000111111111111;//0111 (becomes 10)
						endcase
					end else begin
						compensatedWriteDataToDrive <= compensatedWriteDataToDrive<<1;
					end

					if(SPIWriteWordCounter > 133) begin
						SPIWriteWordCounter <= 8'b0;
						FIFOReadEnable <= 0;
						curSPIBit <= 4'b0;
						writeGate <= 0;
						compensatedWriteDataToDrive <= 16'b1111111111111111;
						inhibit_read <= 0;
						cnc_state <= CNC_IDLE;
					end						
				end
				
				default:
					cnc_state <= CNC_IDLE;
			endcase
		end
	end
	 
	 //Shift in the SPI command word if not empty
	 //Once we have enough bits for instruction decode (so a FSM is needed)
	 
	 //IDLE
		//wait for not FIFO empty
	 //Instruction Decode (6 bit command, 10 bits data)
		//If read command, do position (head, cyl in the other 10 bits as customary)
	 //Send position command and wait for drive ready then read/write (need to compute cyl difference and check for reposition commands with no effect (because we are there) and filter)
	 //read -> idle (maybe)
	 //write wait for prog_full then queue write
	 //wait for our sector number to come up and state PO1 (TIMING IS EVERYTHING HERE) then start shifting data out, also, inhibit the reading
	 
	 
	 


endmodule
