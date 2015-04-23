#ifndef USB_MSC_HANDLERS_H_
#define USB_MSC_HANDLERS_H_

#include <stdint.h>

uint32_t USB_MSC_BlockCount(void *drive);
uint32_t USB_MSC_BlockSize(void *drive);

extern void* USB_MSC_Open(uint32_t driveNum);
extern void USB_MSC_Close(void *drive);

extern uint32_t USB_MSC_Read(void *drive, uint8_t *data, uint32_t sectorNum, uint32_t count);
extern uint32_t USB_MSC_Write(void *drive, uint8_t *data, uint32_t sectorNum, uint32_t count);

#endif
