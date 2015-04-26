#include <stdbool.h>
#include <stdint.h>

#include "driverlib/usb.h"

#include "usblib/usblib.h"
#include "usblib/usb-ids.h"
#include "usblib/device/usbdevice.h"
#include "usblib/device/usbdmsc.h"

#include "USB_MSC_Handlers.h"
#include "USB_MSC_Structures.h"

//Needed by usblib
#define MSC_BUFFER_SIZE 512
#define DESCRIPTOR_TABLE_SIZE ( sizeof(usbDescriptorTable)/sizeof(uint8_t *) )

//Language table (I have no idea why this is required)
const uint8_t usbDescriptor_language[] = { 4, USB_DTYPE_STRING, USBShort(USB_LANG_EN_US) };

//Manufacturer
const uint8_t usbDescriptor_manufacturer[] = { (21 + 1) * 2, USB_DTYPE_STRING,
											'C', 0, 'h', 0, 'r', 0, 'i', 0, 's', 0, 't', 0, 'o', 0, 'p', 0,
											'h', 0, 'e', 0, 'r', 0, 'P', 0, 'a', 0, 'r', 0, 'i', 0, 's', 0,
											'h', 0, '.', 0, 'c', 0, 'o', 0, 'm', 0 };

//Product name reported to the PC
const uint8_t usbDescriptor_product[] = { (19 + 1) * 2, USB_DTYPE_STRING,
											'R', 0, 'L', 0, '-', 0, '0', 0, '2', 0, ' ', 0, 'U', 0, 'S', 0,
											'B', 0, ' ', 0, 'I', 0, 'n', 0, 't', 0, 'e', 0, 'r', 0, 'f', 0,
											'a', 0, 'c', 0, 'e', 0 };

//Serial number
const uint8_t usbDescriptor_serialNumber[] = { (9 + 1) * 2, USB_DTYPE_STRING,
											'P', 0, 'R', 0, 'O', 0, 'T', 0, 'O', 0, 'T', 0, 'Y', 0, 'P', 0,
											'E', 0 };

//USB interface descriptor (USB MSC uses bulk transport)
const uint8_t usbDescriptor_interface[] = { (19 + 1) * 2, USB_DTYPE_STRING,
											'B', 0, 'u', 0, 'l', 0, 'k', 0, ' ', 0, 'D', 0, 'a', 0, 't', 0,
											'a', 0, ' ', 0, 'I', 0, 'n', 0, 't', 0, 'e', 0, 'r', 0, 'f', 0,
											'a', 0, 'c', 0, 'e', 0 };

//USB configuration type (I really don't understand why USB had to be so design-by-committeesq)
const uint8_t usbDescriptor_config[] = { (23 + 1) * 2, USB_DTYPE_STRING,
											'B', 0, 'u', 0, 'l', 0, 'k', 0, ' ', 0, 'D', 0, 'a', 0, 't', 0,
											'a', 0, ' ', 0, 'C', 0, 'o', 0, 'n', 0, 'f', 0, 'i', 0, 'g', 0,
											'u', 0, 'r', 0, 'a', 0, 't', 0, 'i', 0, 'o', 0, 'n', 0 };

//Table holds all these USB descriptor strings so they can be pointed to
const uint8_t * const usbDescriptorTable[] = { usbDescriptor_language, usbDescriptor_manufacturer,
											usbDescriptor_product, usbDescriptor_serialNumber,
											usbDescriptor_interface, usbDescriptor_config };

//The device structure is what is passed (via the USB library) to the PC
tUSBDMSCDevice USB_deviceStructure =
{
    USB_VID_TI_1CBE, //Vendor ID (Used the provided one from TI)
    USB_PID_MSC, //Product ID (Used the provided one from TI)
    "OSHW    ", //Vendor
    "RL02 USB ADAPTER", //Product Name
    "0.01", //Version Number
	200, //200Ma //TODO is this in units of 1mA or 2mA?
    USB_CONF_ATTR_BUS_PWR, //This is a bus powered device
	usbDescriptorTable, //Here's the pointer to the usb descriptors
    DESCRIPTOR_TABLE_SIZE, //Byte size of descriptor table
	{ //Targets for the USB callback handler
        USB_MSC_Open, USB_MSC_Close, USB_MSC_Read,
        USB_MSC_Write, USB_MSC_BlockCount, USB_MSC_BlockSize,
    },
    USB_MSC_CallbackEventHandler //The actual handler for the USB callbacks
};
