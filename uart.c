/*
 *   uart.c
 *   @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 *   @date
 */

#include <inc/tm4c123gh6pm.h>
#include <stdint.h>
#include "uart.h"

void uart_init(void)
{
    SYSCTL_RCGCGPIO_R |= 0x02; //clock to port B
    //enable clock to UART1
    SYSCTL_RCGCUART_R |= 0x02;  //enables clock to uart 1
    while ((SYSCTL_PRGPIO_R & 0x02) == 0)
    {
    }
    while ((SYSCTL_PRUART_R & 0x02) == 0)
    {
    }  //amkes sure the GPIO and UART peripherals are ready
    GPIO_PORTB_AFSEL_R |= 0x03;  //enables alt functionality
    GPIO_PORTB_DEN_R |= 0x03;  //digital enable
    GPIO_PORTB_PCTL_R &= ~0x000000FF;
    GPIO_PORTB_PCTL_R |= 0x00000011;
    uint16_t iBRD = 8;
    uint16_t fBRD = 44; //use equations to get the same
    UART1_CTL_R &= ~0x0001;
    UART1_IBRD_R = iBRD;
    UART1_FBRD_R = fBRD;
    UART1_LCRH_R = 0x60;
    UART1_CC_R = 0x0;
    UART1_CTL_R = 0x301;
}

void uart_sendChar1(char data)
{
    while (UART1_FR_R & 0x20); //busy wait loop to implement the same
    UART1_DR_R = data;
}

char uart_receive(void)
{
    while (UART1_FR_R & 0x10);//blocking uart function
    return (char) (UART1_DR_R & 0xFF);
}

void uart_sendStr1(const char *data)
{
    int i;
    int length = strlen(data);
    for (i = 0; i < length; i++)
    {
        uart_sendChar1(data[i]);
    }
}
