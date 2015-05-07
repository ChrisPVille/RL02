`timescale 1ns / 1ps

module top_sch(clk_in, 
               Drive_mfm_in, 
               Drive_sector_in, 
               rst_in, 
               SPI_clk, 
               SPI_CS, 
               SPI_MOSI, 
               SPI_CurWordIsHeader, 
               drive_command_n, 
               drive_command_p, 
               drive_sel0_n, 
               drive_sel0_p, 
               drive_sel1_n, 
               drive_sel1_p,
					drive_clock_p,
					drive_clock_n,
					writeGate_p,
					writeGate_n,
					writeData_p,
					writeData_n,
					drive_ready,
               SPI_CommandAndWriteEmpty, 
               SPI_DataWAIT, 
               SPI_MISO, 
               crcInvalid, 
               commandAndWriteFIFO_prog_full);

    input clk_in;
    input Drive_mfm_in;
    input Drive_sector_in;
    input rst_in;
    input SPI_clk;
    input SPI_CS;
    input SPI_MOSI;
	 input drive_ready;
	 
   output drive_command_n;
   output drive_command_p;
   output drive_sel0_n;
   output drive_sel0_p;
   output drive_sel1_n;
   output drive_sel1_p;
	output writeData_p;
	output writeData_n;
	output writeGate_p;
	output writeGate_n;
   output SPI_CommandAndWriteEmpty;
	output SPI_CurWordIsHeader;
   output SPI_DataWAIT;
   output SPI_MISO;
   output crcInvalid;
   output commandAndWriteFIFO_prog_full;
	output drive_clock_p;
	output drive_clock_n;
   
   wire currentRealBit;
   wire currentRealBitValid;
   wire skipMFMBit;
   wire MFMEdgeStrobe;
   wire [2:0] decode_state;
   wire headerBitIn;
   wire headerBitInStrobe;
   wire drive_sel0;
   wire drive_sel1;
	wire writeData;
	wire drive_clock;
	wire writeGate;
   wire mfmData;
   wire [8:0] cylNum;
   wire [5:0] sectorNum;
   wire headNumReady;
   wire headNum;
   wire cylNumReady;
   wire sectorNumReady;
   wire FIFOReadEnable;
   wire drive_command;
	wire [16:0] dataOut;
   wire dataOutReady;
	wire inhibit_read;
	wire rst_ReadDatapath;
	wire beginWriteNow;
	wire rst_in;
	wire SPI_FIFOAcceptingData;
	wire SPIInterface_DataAvailable;
	wire [15:0] internalMOSI;
	wire [16:0] internalMISO;
	wire [15:0] SPICommandWord;
	wire SPI_clk_sync;
	
	assign SPI_CurWordIsHeader = internalMISO[16];
															
   commandAndWriteFIFO  commandAndWriteFIFO0 (.din(internalMOSI), 
                                             .clk(clk_in), 
                                             .rd_en(FIFOReadEnable), 
                                             .srst(rst_in), 
                                             .wr_en(SPIInterface_DataAvailable), 
                                             .dout(SPICommandWord), 
															.empty(SPI_CommandAndWriteEmpty),
                                             .full(), 
                                             .prog_full(commandAndWriteFIFO_prog_full));
															
   dataFIFO  dataFIFO0 (.din(dataOut), 
                       .rd_en(SPIInterface_DataAvailable), 
                       .srst(rst_ReadDatapath), 
                       .clk(clk_in), 
                       .wr_en(dataOutReady), 
                       .dout(internalMISO), 
                       .empty(SPI_DataWAIT), 
                       .full(), 
							  .prog_empty(SPI_FIFOAcceptingData));
							  
	spi_slave spi0 (.clk(clk_in),
				 .rst(rst_in),
				 .ss(SPI_CS),
				 .mosi(SPI_MOSI),
				 .miso(SPI_MISO),
				 .sck(SPI_clk_sync),
				 .done(SPIInterface_DataAvailable),
				 .din(internalMISO[15:0]),
				 .dout(internalMOSI));
							  
	OR2 FSMResetOR (.I0(rst_in),
						 .I1(inhibit_read),
						 .O(rst_ReadDatapath));
						 
								 
   headerDecode  headerDecode0 (.clk(clk_in), 
                               .decode_state(decode_state[2:0]), 
                               .headerBitIn(headerBitIn), 
                               .headerBitInStrobe(headerBitInStrobe), 
                               .rst(rst_ReadDatapath), 
                               .crcInvalid(crcInvalid), 
                               .cylNum(cylNum[8:0]), 
                               .cylNumReady(cylNumReady), 
                               .headNum(headNum), 
                               .headNumReady(headNumReady), 
                               .sectorNum(sectorNum[5:0]), 
                               .sectorNumReady(sectorNumReady));
								
   decodeFSM  decodeFSM0 (.clk(clk_in), 
                         .currentRealBit(currentRealBit), 
                         .currentRealBitValid(currentRealBitValid), 
                         .prog_empty(SPI_FIFOAcceptingData), 
                         .rst(rst_ReadDatapath), 
                         .sectorPulse(sectorPulse), 
                         .wordOut(dataOut), 
                         .wordOutReady(dataOutReady), 
                         .decode_state(decode_state[2:0]), 
                         .headerOut(headerBitIn), 
                         .headerOutStrobe(headerBitInStrobe), 
                         .skipMFMBit(skipMFMBit),
								 .beginWriteNow(beginWriteNow));
								 
							  
   mfmDecode  mfmDecode0 (.clk(clk_in), 
                         .mfmEdge(MFMEdgeStrobe), 
                         .mfmIn(mfmData), 
                         .rst(rst_in), 
                         .skipMFMBit(skipMFMBit), 
                         .currentRealBit(currentRealBit), 
                         .currentRealBitValid(currentRealBitValid));
								 
   edgeDetect  mfmEdgeDetect (.clk(clk_in), 
                             .data(mfmData), 
                             .rst(rst_in), 
                             .strobe(MFMEdgeStrobe));
									  
   inputSync  mfmInputSync (.async_in(Drive_mfm_in), 
                           .clk(clk_in), 
                           .rst(rst_in), 
                           .sync_out(mfmData));
									
	inputSync  readySync (.async_in(Drive_sector_in), 
                           .clk(clk_in), 
                           .rst(rst_in), 
                           .sync_out(sectorPulse));
									
	inputSync  sectorSync (.async_in(drive_ready), 
                           .clk(clk_in), 
                           .rst(rst_in), 
                           .sync_out(driveReady));
	
	inputSync  SPIclkSync (.async_in(SPI_clk), 
                           .clk(clk_in), 
                           .rst(rst_in), 
                           .sync_out(SPI_clk_sync));
						 
   driveControl  driveControl0 (.clk(clk_in), 
												 .cylNumIn(cylNum[8:0]), 
												 .cylNumInReady(cylNumReady), 
												 .headNumIn(headNum), 
												 .headNumInReady(headNumReady), 
												 .rst(rst_in), 
												 .sectorNumIn(sectorNum[5:0]), 
												 .sectorNumInReady(sectorNumReady), 
												 .sector_pulse(sectorPulse), 
												 .SPICommandWord(SPICommandWord), 
												 .SPIFIFOEmpty(SPI_CommandAndWriteEmpty), 
												 .drive_command(drive_command), 
												 .FIFOReadEnable(FIFOReadEnable), 
												 .inhibit_read(inhibit_read), 
												 .writeData(writeData), 
												 .writeGate(writeGate),
												 .drive_ready(driveReady),
												 .drive_clock(drive_clock),
												 .beginWriteNow(beginWriteNow),
												 .SPIProgFull(commandAndWriteFIFO_prog_full)); 
												 
	GND  XLXI_51 (.G(drive_sel0));
	
   GND  XLXI_53 (.G(drive_sel1));
	
	//The drive attributes have to be here because the OBUF construct has a default value
   OBUF #(.DRIVE(16)) drivesel0_bufp (.I(drive_sel0), 
                   .O(drive_sel0_p));
						 
	OBUF #(.DRIVE(16)) drivesel0_bufn (.I(~drive_sel0), 
                   .O(drive_sel0_n));
						 
	OBUF #(.DRIVE(16)) drivesel1_bufp (.I(drive_sel1), 
                   .O(drive_sel1_p));
						 
	OBUF #(.DRIVE(16)) drivesel1_bufn (.I(~drive_sel1), 
                   .O(drive_sel1_n));
					 
	OBUF #(.DRIVE(16)) writeData_bufp (.I(writeData), 
                   .O(writeData_p));
						 
	OBUF #(.DRIVE(16)) writeData_bufn (.I(~writeData), 
                   .O(writeData_n));
					 
	/*OBUFDS  XLXI_63 (.I(writeGate), 
					 .O(writeGate_p), 
					 .OB(writeGate_n));*/
					 
	OBUF #(.DRIVE(16)) writeGate_bufp (.I(writeGate), 
					 .O(writeGate_p));
	OBUF #(.DRIVE(16)) writeGate_bufn (.I(~writeGate), 
					 .O(writeGate_n));
					 
	OBUF #(.DRIVE(16)) driveClock_bufp (.I(drive_clock), 
					 .O(drive_clock_p));
	OBUF #(.DRIVE(16)) driveClock_bufn (.I(~drive_clock), 
					 .O(drive_clock_n));
					 
	OBUF #(.DRIVE(16)) drive_command_bufp (.I(drive_command), 
					 .O(drive_command_p));
	OBUF #(.DRIVE(16)) drive_command_bufn (.I(~drive_command), 
					 .O(drive_command_n));
				
endmodule
