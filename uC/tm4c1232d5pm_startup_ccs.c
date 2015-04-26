#include <stdint.h>

#include "inc/hw_types.h"
#include "inc/hw_nvic.h"

//Make sure the linker puts the vector table in the right spot
#pragma DATA_SECTION(vectorTable, ".intvecs")

extern void _c_int00(void); //C Entry routine
extern void USB0DeviceIntHandler(void); //usblib ISR

extern uint32_t __STACK_TOP; //Used by the linker script

//Jump the the c initialization function
void ISR_Reset(void)
{
    __asm("    .global _c_int00\n"
          "    b.w     _c_int00");
}

//Non-Maskable Interrupt handler
void ISR_NMI(void)
{
    //Trap here
    while(1);
}

//Hard Fault handler (usually happens when trying to access peripherals that are off (derp))
//See the datasheet for details
void ISR_HardFault(void)
{
    //Trap here
    while(1);
}

//ISR for when an interrupt with no handler was called (probably the programmer's fault)
void ISR_Default(void)
{
    //Trap here
    while(1);
}

//Vector table
void (*const vectorTable[]) (void) =
{
    (void (*)(void)) ((uint32_t) & __STACK_TOP), //Stack pointer goes in the first address
    ISR_Reset,          //Reset
    ISR_NMI,            //NMI
    ISR_HardFault,      //Hard fault
    ISR_Default,        //MPU/MMU fault
    ISR_Default,        //Bus fault
    ISR_Default,        //Usage fault
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //Supervisor call
    ISR_Default,        //Debug Monitor handler
    0,                  //Unused
    ISR_Default,        //"PendSV" aka Please supervisor, service my every whim handler
    ISR_Default,        //System Tick
    ISR_Default,        //GPIO A
    ISR_Default,        //GPIO B
    ISR_Default,        //GPIO C
    ISR_Default,        //GPIO D
    ISR_Default,        //GPIO E
    ISR_Default,        //UART0
    ISR_Default,        //UART1
    ISR_Default,        //SSI0
    ISR_Default,        //I2C0
    ISR_Default,        //PWM0 Fault
    ISR_Default,        //PWM0 0
    ISR_Default,        //PWM0 1
    ISR_Default,        //PWM0 2
    ISR_Default,        //Quadrature 0
    ISR_Default,        //ADC 0
    ISR_Default,        //ADC 1
    ISR_Default,        //ADC 2
    ISR_Default,        //ADC 3
    ISR_Default,        //Watchdog
    ISR_Default,        //Timer 0A
    ISR_Default,        //Timer 0B
    ISR_Default,        //Timer 1A
    ISR_Default,        //Timer 1B
    ISR_Default,        //Timer 2A
    ISR_Default,        //Timer 2B
    ISR_Default,        //Analog Comparator 0
    ISR_Default,        //Analog Comparator 1
    ISR_Default,        //Analog Comparator 2
    ISR_Default,        //System Control Interrupt
    ISR_Default,        //FLASH
    ISR_Default,        //GPIO F
    ISR_Default,        //GPIO G
    ISR_Default,        //GPIO H
    ISR_Default,        //UART2
    ISR_Default,        //SSI1
    ISR_Default,        //Timer 3A
    ISR_Default,        //Timer 3B
    ISR_Default,        //I2C1
    ISR_Default,        //Quadrature 1
    ISR_Default,        //CAN0
    ISR_Default,        //CAN1
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //Hibernation
    USB0DeviceIntHandler, // USB0
    ISR_Default,        //PWM0 3
    ISR_Default,        //uDMA Software Req
    ISR_Default,        //uDMA Fault
    ISR_Default,        //ADC1 0
    ISR_Default,        //ADC1 1
    ISR_Default,        //ADC1 2
    ISR_Default,        //ADC1 3
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //GPIO J
    ISR_Default,        //GPIO K
    ISR_Default,        //GPIO L
    ISR_Default,        //SSI2
    ISR_Default,        //SSI3
    ISR_Default,        //UART3
    ISR_Default,        //UART4
    ISR_Default,        //UART5
    ISR_Default,        //UART6
    ISR_Default,        //UART7
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //I2C2
    ISR_Default,        //I2C3
    ISR_Default,        //Timer 4A
    ISR_Default,        //Timer 4B
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //Timer 5A
    ISR_Default,        //Timer 5B
    ISR_Default,        //Timer 0A Wide
    ISR_Default,        //Timer 0B Wide
    ISR_Default,        //Timer 1A Wide
    ISR_Default,        //Timer 1B Wide
    ISR_Default,        //Timer 2A Wide
    ISR_Default,        //Timer 2B Wide
    ISR_Default,        //Timer 3A Wide
    ISR_Default,        //Timer 3B Wide
    ISR_Default,        //Timer 4A Wide
    ISR_Default,        //Timer 4B Wide
    ISR_Default,        //Timer 5A Wide
    ISR_Default,        //Timer 5B Wide
    ISR_Default,        //FPU
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //I2C4
    ISR_Default,        //I2C5
    ISR_Default,        //GPIO M
    ISR_Default,        //GPIO N
    ISR_Default,        //Quadrature 2
    0,                  //Unused
    0,                  //Unused
    ISR_Default,        //GPIO P0/All
    ISR_Default,        //GPIO P1
    ISR_Default,        //GPIO P2
    ISR_Default,        //GPIO P3
    ISR_Default,        //GPIO P4
    ISR_Default,        //GPIO P5
    ISR_Default,        //GPIO P6
    ISR_Default,        //GPIO P7
    ISR_Default,        //GPIO Q0/All
    ISR_Default,        //GPIO Q1
    ISR_Default,        //GPIO Q2
    ISR_Default,        //GPIO Q3
    ISR_Default,        //GPIO Q4
    ISR_Default,        //GPIO Q5
    ISR_Default,        //GPIO Q6
    ISR_Default,        //GPIO Q7
    ISR_Default,        //GPIO R
    ISR_Default,        //GPIO S
    ISR_Default,        //PWM1 0
    ISR_Default,        //PWM1 1
    ISR_Default,        //PWM1 2
    ISR_Default,        //PWM1 3
    ISR_Default         //PWM1 Fault
};
