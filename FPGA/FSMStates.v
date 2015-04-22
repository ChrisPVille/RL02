//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:29:16 02/21/2015 
// Design Name: 
// Module Name:    FSMStates 
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

// State encodings
parameter [2:0]
DSFM_INIT     = 3'b000, //Wait here until current real bit valid then v
DSFM_PR1		 = 3'b001, //Stay in this until current real bit == 1 then v,
DSFM_HDR		 = 3'b010, //Do decoding stuffs here then v (data goes into output reg with valid flag?)
DSFM_PO1      = 3'b011, //inhibit sampling until end of PO1 (maybe a timeout? consult datasheet.)
DSFM_IT_IDLE  = 3'b100, //After timeout or whatever wait here until current real bit is valid then v
DSFM_PR2      = 3'b101, //stay in this until current real bit == 1 then v
DSFM_DATA     = 3'b110, //Present data (we might have to do some inhibiting or trickery when it comes time to write) (data can go to async FIFO for SPI readout)
DSFM_PO2      = 3'b111; //inhibiting sampling until data timeout or whatever mechanism is used (see PO1)  
