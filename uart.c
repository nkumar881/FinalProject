/**
 * Driver for ping sensor
 * @file ping.c
 *  @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 */

#include "ping.h"
#include "Timer.h"
#include "driverlib/interrupt.h"
#include "uart-interrupt.h"
#include "lcd.h"

volatile unsigned long START_TIME = 0;
volatile unsigned long END_TIME = 0;
volatile enum
{
    LOW, HIGH, DONE
} STATE = LOW; // State of ping echo pulse

int cycles = 0;

void ping_init(void)
{

    SYSCTL_RCGCGPIO_R |= 0x02; //Enable GPIO clock on PORTB
    while ((SYSCTL_PRGPIO_R & 0x02) == 0)
    {
    }; //Wait for PORTB to initialize
    SYSCTL_RCGCTIMER_R |= 0x08; //Enable timer clock
    while ((SYSCTL_PRTIMER_R & 0x08) == 0)
    {
    }; //Wait for Timer 3B to initialize
    GPIO_PORTB_DEN_R |= 0x08; //Enable digital on PB3
    GPIO_PORTB_DIR_R &= ~0x08; //Set PB3 to input
    GPIO_PORTB_AFSEL_R |= 0x08; //Enable alternate functions on PB3
    GPIO_PORTB_PCTL_R = (GPIO_PORTB_PCTL_R & ~0x00007000) | 0x00007000; //Clears then sets the alt function of pin 3 to T3CCP1
    TIMER3_CTL_R &= ~(0x100); //Disable timer 3B
    TIMER3_CFG_R = 0x00000004;
    TIMER3_TBMR_R |= 0x7;
    TIMER3_CTL_R |= 0xC00;
    TIMER3_TBPR_R |= 0xFF;
    TIMER3_TBILR_R |= 0xFFFF;
    TIMER3_IMR_R |= 0x400;
    TIMER3_ICR_R |= 0x400;
    NVIC_EN1_R = 0x00000010;
    NVIC_PRI9_R = (NVIC_PRI9_R & 0xFFFFFF0F) | 0x00000020;
    IntRegister(INT_TIMER3B, TIMER3B_Handler);
    IntMasterEnable();
    TIMER3_CTL_R |= 0x100;
}

void ping_trigger(void)
{
    STATE = LOW;

    TIMER3_CTL_R &= ~(0x100);
    TIMER3_IMR_R &= ~(0x400);
    GPIO_PORTB_AFSEL_R &= ~(0x08);
    GPIO_PORTB_DIR_R |= 0x08;
    GPIO_PORTB_DATA_R &= 0x07;
    timer_waitMicros(5);
    GPIO_PORTB_DATA_R |= 0x08;
    timer_waitMicros(5);
    GPIO_PORTB_DATA_R &= 0x07;
    GPIO_PORTB_DIR_R &= ~0x08;
    TIMER3_ICR_R |= 0x400;
    GPIO_PORTB_AFSEL_R |= 0x08; 
    TIMER3_IMR_R |= 0x400;
    TIMER3_CTL_R |= 0x100; 
}

void TIMER3B_Handler(void)
{
    if (TIMER3_MIS_R & 0x400)
    { 
        TIMER3_ICR_R |= 0x400; 
        if (STATE == LOW)
        { 
            START_TIME = TIMER3_TBR_R;
            STATE = HIGH;
        }
        else if (STATE == HIGH)
        {
            END_TIME = TIMER3_TBR_R;
            STATE = DONE;
        }

    }

}

float ping_getDistance(void)
{


    char array[100];
    ping_trigger();
    while (STATE != DONE)
    {
    };
    int overflow = (START_TIME < END_TIME);
    float temp;
    if (overflow == 1)
    { 
        temp = (((unsigned long) 0xFFFFFF) - END_TIME) + START_TIME;
        temp /= 16000000;
        sprintf(array, "OF: %f\n", temp);
        lcd_printf(array);
        temp = (temp * 343) * 50;
    }
    else
    {
        temp = START_TIME - END_TIME; 
        temp /= 16000000; 
        sprintf(array, "%f\n", temp);
        lcd_printf(array);
        temp = (temp * 343) * 50;
    }

    return temp;

}
