/*
 *
 *   uart-interrupt.c
 *
 *   @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 *   @date
 */

#include <inc/tm4c123gh6pm.h>
#include <stdint.h>
#include "uart-interrupt.h"

// These variables are declared as examples for your use in the interrupt handler.
volatile char command_byte = -1; // byte value for special character used as a command
volatile int command_flag = 0; // flag to tell the main program a special command was received
volatile char toPrint = 0;

void uart_interrupt_init(void)
{
    SYSCTL_RCGCGPIO_R |= 0x02;
    SYSCTL_RCGCUART_R |= 0x02;
    while ((SYSCTL_PRGPIO_R & 0x02) == 0)
    {
    };
    while ((SYSCTL_PRUART_R & 0x02) == 0)
    {
    };
    GPIO_PORTB_DEN_R |= 0x03;
    GPIO_PORTB_AFSEL_R |= 0x03;
    GPIO_PORTB_PCTL_R &= ~0x000000FF;
    GPIO_PORTB_PCTL_R |= 0x00000011;
    uint16_t iBRD = 8;
    uint16_t fBRD = 44;
    UART1_CTL_R &= ~0x0001;
    UART1_IBRD_R = iBRD;
    UART1_FBRD_R = fBRD;
    UART1_LCRH_R = 0x60;
    UART1_CC_R = 0x0;
    UART1_ICR_R |= 0b00010000;
    UART1_IM_R |= 0x00000010;
    NVIC_PRI1_R = (NVIC_PRI1_R & 0xFF0FFFFF) | 0x00200000;
    NVIC_EN0_R |= (1 << 6);
    IntRegister(INT_UART1, UART1_Handler);
    IntMasterEnable();
    UART1_CTL_R |= (0x00000001 | 0x00000200 | 0x00000100);

}

void uart_sendChar(char data)
{

    while ((UART1_FR_R & UART_FR_TXFF) != 0);
    UART1_DR_R = data;
}


void uart_sendStr(const char *data)
{
    int i;
    int length = strlen(data);
    for (i = 0; i < length; i++)
    {
        uart_sendChar(data[i]);
    }
}

// Interrupt handler for receive interrupts
void UART1_Handler(void)
{
    char byte_received;

    if (UART1_MIS_R & 0x10)
    {

        UART1_ICR_R |= 0b00010000;

        byte_received = (char) (UART1_DR_R & 0xFF);
        uart_sendChar(byte_received);


        if (byte_received == '\r')
        {

            uart_sendChar('\n');
        }
        else
        {
            if (byte_received == command_byte)
            {
                command_flag = 1;
            }
        }
    }
}
