#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#include "inc/hw_ints.h"
#include "inc/hw_memmap.h"
#include "inc/hw_types.h"

#include "driverlib/gpio.h"
#include "driverlib/interrupt.h"
#include "driverlib/rom.h"
#include "driverlib/ssi.h"
#include "driverlib/sw_crc.h"
#include "driverlib/sysctl.h"
#include "driverlib/systick.h"

#include "usblib/usblib.h"
#include "usblib/usb-ids.h"
#include "usblib/device/usbdevice.h"
#include "usblib/device/usbdmsc.h"

#include "USB_MSC_Structures.h"

//TODO File is a mess, re-architect so that the reading logic is smarter regarding seeks
//Ideally, the controller will cache things as they fly by, but without a threading library
//that isn't going to support interruption by USB very well.  Alternatively, the seek logic
//should be folded into the read USB function

uint16_t*sectorBuffer;
uint_fast8_t sectorBufferValid[40];
uint_fast16_t prevSeekTrack;
uint_fast8_t prevSeekHead;

uint32_t i;

#define DRIVE_ATTACHED 1
#define DRIVE_LOADED   2

#define ERR_INVALID_PARAMS  -1
#define ERR_HEADER_CRC_FAIL -2
#define ERR_SEEK_FAILED     -3

struct
{
    uint_fast8_t driveFlags;
} driveInstance;

//This is the first pass at the seek function.
//Now that crunch time is over, the entire USB end needs some rearchitecting
//
int32_t seek(void *drive, uint_fast8_t head, uint_fast16_t track)
{
    if(drive == 0)
        return ERR_INVALID_PARAMS;

    uint32_t failedSeek = 0;
    uint32_t badSectorHeader = 0;

    uint_fast16_t lastCyl = 0xFFFF;
    uint_fast8_t lastHead = 0xFF;

    uint_fast8_t justReturnCurSector = 0;

    uint32_t position = 0;

    uint32_t headerWord = 0;
    uint32_t reservedWord = 0;
    uint32_t CRC = 0;
    uint32_t dontCare = 0;

    if(head>1 || track > 511)
    {
        while(1) ;  //TODO Remove - Trap here for examination
        return ERR_INVALID_PARAMS;
    }

    //TODO We really shouldn't just trust that the heads are where we left them
    if(prevSeekTrack == track && prevSeekHead == head)
    {
        justReturnCurSector = 1;
    }

    while(1) //Breakout on successful location of track or unrecoverable failure
    {
        //TODO There is a timing problem here because the FPGA may not have yet asserted that data is invalid (if the FPGA gets a command, it should assert data WAIT directly)
        while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
        if(!GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_6)) //If this isn't a header word
        {
            //Discard a word
            SSIDataPut(SSI0_BASE,0);
            while(SSIBusy(SSI0_BASE)) ;
            SSIDataGet(SSI0_BASE, &dontCare);
        }
        else //If this is a header word
        {
            uint16_t calculatedCRC;
            uint8_t crcPack[2];

            //Store the word in the proper place
            SSIDataPut(SSI0_BASE,0);
            while(SSIBusy(SSI0_BASE)) ;
            SSIDataGet(SSI0_BASE, &headerWord);

            crcPack[0] = headerWord & 0xFF;
            crcPack[1] = (headerWord>>8) & 0xFF;
            calculatedCRC = Crc16(0, (const uint8_t*)crcPack, 2);

            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
            SSIDataPut(SSI0_BASE, 0);
            while(SSIBusy(SSI0_BASE)) ;
            SSIDataGet(SSI0_BASE, &reservedWord);

            crcPack[0] = reservedWord & 0xFF;
            crcPack[1] = (reservedWord>>8) & 0xFF;
            calculatedCRC = Crc16(calculatedCRC, (const uint8_t*)crcPack, 2);

            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
            SSIDataPut(SSI0_BASE, 0);
            while(SSIBusy(SSI0_BASE)) ;
            SSIDataGet(SSI0_BASE, &CRC);

            if(CRC != calculatedCRC)
            {
                badSectorHeader++;
                if(badSectorHeader>40) //If there is a truly bad header, there will be a 50ms penalty before giving up, but we are insensative to a run of two bad sectors
                {
                    while(1) ;  //TODO Remove - Trap here for examination
                    return ERR_HEADER_CRC_FAIL;
                }
                continue; //Look for another sector
            }

            //If we've previously calculated that we don't need to seek
            if(justReturnCurSector)
            {
                return headerWord & 0b111111;
            }

            //Do some bit-fu on the incoming data
            uint_fast16_t cylFromDrive = (headerWord>>7) & 0b111111111;
            uint_fast8_t headFromDrive = (headerWord>>6) & 0b1;

            lastCyl = cylFromDrive;
            lastHead = headFromDrive;

            //If we've landed on the requested track
            if(cylFromDrive == track && headFromDrive == head)
            {
                prevSeekHead = head;
                prevSeekTrack = track;

                return headerWord & 0b111111; //We are done seeking, return the current sector
            }
            else //If we need to move still, issue our seek command
            {
                //This is the command word to the FPGA
                position = 0b0010000000000000;

                if(track>cylFromDrive) //If we need to move inwards
                {
                    position |= (track-cylFromDrive);
                    position |= 1<<9; //Move towards the spindle
                }
                else //If we need to move outwards
                {
                    position |= (cylFromDrive-track);
                }
                position |= head<<10;

                //The drive is mis-seeking and we're stuck on the same track for more than 3 iterations
                //Perterb the heads additional tracks. At least two drives were observed with this problem
                if(failedSeek%4==3 && cylFromDrive==lastCyl && headFromDrive==lastHead)
                {
                    if(cylFromDrive < 255) //if we're stuck on the outward part of the disk
                    {
                        position += 1; //Lets try to move an extra track inward (2 tracks then 3, etc.)
                    }
                    else //if we're stuck on the inward part of the disk
                    {
                        position -= 1; //Lets try to move an additional track outward
                    }
                }

                if(failedSeek > 15)
                {
                    //TODO Maybe record the offending seeks
                    while(1) ;  //TODO Remove - Trap here for examination
                    return ERR_SEEK_FAILED;
                }

                while(!GPIOPinRead(GPIO_PORTF_BASE, GPIO_PIN_2)) ;  //Wait for the command FIFO to empty
                //Issue the move command
                SSIDataPut(SSI0_BASE, position);
                while(SSIBusy(SSI0_BASE)) ;
                SSIDataGet(SSI0_BASE, &dontCare);

                //Invalidate the read cache
                for(i = 0; i<40; i++)
                {
                    sectorBufferValid[i] = 0;
                }

                //Track the number of seek commands sent to the drive this function call
                failedSeek++;
            }
        }
    }
}

uint32_t USB_MSC_BlockCount(void *drive)
{
    //Maybe exclude the last Cyl as it contains the bad sector information.  In the future, we can read it out and map around the bad sectors
    //TODO This will need to change for the RL01. We can probably auto-detect by doing a max seek and reading the resulting track (512 for RL02, 256 for RL01)
    return(20480);
}


uint32_t USB_MSC_BlockSize(void *drive)
{
    //It looks like block device buffer allocations in linux must occur on 512 byte boundries, so we have to report a false sector size and deal with it in software
    return 512;
}


void* USB_MSC_Open(uint32_t driveNum)
{
    uint_fast8_t i;

    if(driveNum > 0)
        return 0;

    if(!sectorBuffer)
    {
        sectorBuffer = (uint16_t*)calloc(40*128,sizeof(uint16_t));
        for(i = 0; i<40; i++)
        {
            sectorBufferValid[i] = 0;
        }
        if(!sectorBuffer)
        {
            return 0;
        }
    }

    //If we try to open to an already attached drive, don't open it again
    if(driveInstance.driveFlags & DRIVE_ATTACHED)
    {
        return(0);
    }

    //TODO Check the drive state field and report just DRIVE_ATTACHED if we are anything but loaded

    seek(0, 0, 0);

    //We can now report that the drive is attached and busy (because we are doing things with it)
    driveInstance.driveFlags = DRIVE_ATTACHED | DRIVE_LOADED;


    return( (void *) &driveInstance);
}


void USB_MSC_Close(void *drive)
{
    if(drive == 0)
        return;

    free(sectorBuffer);
    //TODO Reset drive
}



uint32_t USB_MSC_Read(void *drive, uint8_t *data, uint32_t sectorNum, uint32_t count)
{
    if(drive == 0)
        return 0;

    sectorNum *= 2;
    count *= 2;

    uint_fast8_t sector = 0;
    uint_fast8_t head = 0;
    uint_fast16_t track = 0;

    uint_fast32_t completedBlocks = 0;
    while(completedBlocks<count)
    {
        //Looks like simh uses this layout for logical access. It's not physically optimal.
        head = sectorNum+completedBlocks > 20479 ? 1 : 0;
        sector = (sectorNum+completedBlocks) % 40;
        track = ((sectorNum+completedBlocks) / 40) % 512;

        //This is how the RL02 User guide lists linear access
        /*/ /Entire track, alternating heads
        head = (sectorNum+completedBlocks) % 80 > 39 ? 1 : 0;
        sector = ((sectorNum+completedBlocks) % 40);
        track = ((sectorNum+completedBlocks) / 80) % 512;
        */

        int32_t ret;
        uint32_t dontCare;
        uint32_t headerWord;
        uint32_t reservedWord;
        uint32_t headerCRCWord;
        uint32_t dataWord;
        uint32_t dataCRCWord;

        uint_fast8_t sectorNumberFromDrive;

        ret = seek(drive, head, track); //Seeks are internally a NOP if we're on it.
        if(ret<0) //If the seek failed
        {
            //There's no way to indicate what type of failure occured to the PC, so just tell it we're returning 0 sectors
            return 0;
        }
        sectorNumberFromDrive = ret;

        if(sectorBufferValid[sector]) //If the data we are looking for is in cache
        {
            for(i=0; i<128; i++) //Read it out from cache
            {
                data[(i*2) + (completedBlocks*2*132)] = sectorBuffer[(sector*128)+i] & 0xFF;
                data[(i*2) + (completedBlocks*2*132) + 1] = sectorBuffer[(sector*128)+i]>>8 & 0xFF;
            }
            completedBlocks++;
        }

        else //If our data is not in cache
        {
            while (sectorNumberFromDrive != sector)
            {
                if(!sectorBufferValid[sectorNumberFromDrive]) //If the cache needs to be updated
                {
                    for(i = 0; i<128; i++)
                    {
                        while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                        SSIDataPut(SSI0_BASE, 0);
                        while(SSIBusy(SSI0_BASE)) ;
                        SSIDataGet(SSI0_BASE, &dataWord);

                        sectorBuffer[i+(sectorNumberFromDrive*128)] = dataWord; //Cache the value

                        if(i == 127) //Last Word
                        {
                            //TODO Check the data CRC
                            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                            SSIDataPut(SSI0_BASE, 0);
                            while(SSIBusy(SSI0_BASE)) ;
                            SSIDataGet(SSI0_BASE, &dataCRCWord);
                        }
                    }
                    sectorBufferValid[sectorNumberFromDrive] = 1; //Mark the sector as cached
                }
                else //Else we need to pop off words until we find another sector
                {
                    while(1)
                    {
                        while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                        if(!GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_6)) //If this isn't a header word
                        {
                            //Discard a word
                            SSIDataPut(SSI0_BASE,0);
                            while(SSIBusy(SSI0_BASE)) ;
                            SSIDataGet(SSI0_BASE, &dontCare);
                        }
                        else
                        {
                            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                            SSIDataPut(SSI0_BASE,0);
                            while(SSIBusy(SSI0_BASE)) ;
                            SSIDataGet(SSI0_BASE, &headerWord);

                            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                            SSIDataPut(SSI0_BASE, 0);
                            while(SSIBusy(SSI0_BASE)) ;
                            SSIDataGet(SSI0_BASE, &reservedWord);

                            while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                            SSIDataPut(SSI0_BASE, 0);
                            while(SSIBusy(SSI0_BASE)) ;
                            SSIDataGet(SSI0_BASE, &headerCRCWord);

                            //TODO Check CRC

                            sectorNumberFromDrive = headerWord & 0b111111;

                            break; //If this is a header word, get out of this loop and check it
                        }
                    }
                }
            }

            //At this point, we're on the right track, right head, right sector

            for(i = 0; i<128; i++)
            {
                while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                SSIDataPut(SSI0_BASE, 0);
                while(SSIBusy(SSI0_BASE)) ;
                SSIDataGet(SSI0_BASE, &dataWord);

                //TODO Figure out the word/byte swapping necessary for the common data storage mode (8/12/16 bit disk storage mode? Need expert information)
                data[(i*2) + (completedBlocks*2*132)] = dataWord & 0xFF;
                data[(i*2) + (completedBlocks*2*132) + 1] = dataWord>>8 & 0xFF;
                sectorBuffer[i+(sectorNumberFromDrive*128)] = dataWord; //Cache the value

                if(i == 127) //Last Word
                {
                    //TODO Check the data CRC
                    while(GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7)) ;  //Wait for valid data
                    SSIDataPut(SSI0_BASE, 0);
                    while(SSIBusy(SSI0_BASE)) ;
                    SSIDataGet(SSI0_BASE, &dataCRCWord);
                }
            }
            sectorBufferValid[sectorNumberFromDrive] = 1; //Mark the sector as cached
            completedBlocks++;
        }
    }

    return(count * 256);
}


uint32_t USB_MSC_Write(void *drive, uint8_t *data, uint32_t sectorNum, uint32_t count)
{
    if(drive == 0)
        return 0;

    //Prevent the user from writing until FPGA support is fully qualified
    return 0;
}
