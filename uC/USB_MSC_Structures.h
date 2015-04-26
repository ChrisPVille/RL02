#ifndef USB_MSC_STRUCTURES_H_
#define USB_MSC_STRUCTURES_H_

//Holds all the descriptors and deivce info passed to the PC
extern tUSBDMSCDevice USB_deviceStructure;

//The handler for the usb events is defined in main.c so it can have access to
//whatever resources we want later
extern uint32_t USB_MSC_CallbackEventHandler(void *pvCBData, uint32_t ui32Event, uint32_t ui32MsgParam, void *pvMsgData);

#endif
