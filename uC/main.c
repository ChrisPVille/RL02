#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#include "inc/hw_ints.h"
#include "inc/hw_types.h"
#include "inc/hw_memmap.h"

#include "driverlib/gpio.h"
#include "driverlib/pin_map.h"
#include "driverlib/rom.h"
#include "driverlib/ssi.h"
#include "driverlib/sysctl.h"
#include "driverlib/udma.h"
#include "driverlib/usb.h"

#include "usblib/usblib.h"
#include "usblib/usb-ids.h"
#include "usblib/device/usbdevice.h"
#include "usblib/device/usbdmsc.h"

#include "ucpins.h"
#include "USB_MSC_Structures.h"

//DMA control data structure
#if defined(ccs)
#pragma DATA_ALIGN(DMA_Ctl, 1024)
tDMAControlTable DMA_Ctl[64];
#else //GCC et al
tDMAControlTable DMA_Ctl[64] __attribute__ ((aligned(1024)));
#endif

//Any bulk transport events related to PC->uC communication trigger this function
//Again, I don't exactly understand why this is needed architectually, other than
//it being a callback target in the usb library, beyond our control.
uint32_t RxHandler(void *callback, uint32_t event, uint32_t eventMsg, void *eventPtr)
{
    return (0);
}

//Any bulk transport events related to uC->PC communication trigger this function
uint32_t TxHandler(void *callback, uint32_t event, uint32_t eventMsg, void *eventPtr)
{
    return (0);
}

//This function gets called on the completion of USB related service events.
//We can use this callback to light up LEDs or notify the user in other ways.
uint32_t USB_MSC_CallbackEventHandler(void *callback, uint32_t event, uint32_t eventMsg, void *eventPtr)
{
    return (0);
}


int main(void)
{
    //
    // 50Mhz from the 200Mhz PLL with a 16Mhz crystal input.
    //
    SysCtlClockSet(SYSCTL_SYSDIV_4 | SYSCTL_USE_PLL | SYSCTL_OSC_MAIN | SYSCTL_XTAL_16MHZ);

    //Turn on the uDMA engine
    SysCtlPeripheralEnable(SYSCTL_PERIPH_UDMA);
    SysCtlDelay(10);
    uDMAControlBaseSet(&DMA_Ctl[0]);
    uDMAEnable();

    PortFunctionInit();

    GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_1, GPIO_PIN_1); //Put FPGA core into reset (this is the case when not driving the pin).
    GPIOPinWrite(GPIO_PORTA_BASE, GPIO_INT_PIN_6, 0); //De-Assert Write Enable
    SysCtlDelay(SysCtlClockGet() / 30); //Wait ~100ms

    GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_1, 0); //Bring the FPGA out of reset once we start up
    SysCtlDelay(SysCtlClockGet() / 30); //Wait ~100ms

    //Force the uC into USB device mode (the sense pin may not work due to a silicon bug)
    USBStackModeSet(0, eUSBModeForceDevice, 0);

    //Setup the SPI interface, Normal mode, 16-bit transfer width
    SSIClockSourceSet(SSI0_BASE, SSI_CLOCK_PIOSC);
    //We can't drive the SPI from the 50Mhz system clock (for stupid technical reasons) so drive it from the 16Mhz onboard osc
    SSIConfigSetExpClk(SSI0_BASE, 16000000, SSI_FRF_MOTO_MODE_0, SSI_MODE_MASTER, 8000000, 16);
    SSIEnable(SSI0_BASE);

    //TODO we should allow the attachment of the drive over USB before it is spun up once we have drive status information
    uint32_t zero;
    while (SSIDataGetNonBlocking(SSI0_BASE, &zero)); //The SPI FIFO can be filled with junk, so pop it all out
    while (GPIOPinRead(GPIO_PORTA_BASE, GPIO_PIN_7));  //Wait for valid data from the Drive
    while (!GPIOPinRead(GPIO_PORTF_BASE, GPIO_PIN_2));  //Wait for the command FIFO (on the drive) to empty

    //Startup the USB Device
    USBDMSCInit(0, &USB_deviceStructure);


    while (1);//We could sleep, but this will do something eventually
}

