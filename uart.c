/*
 * @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 */

#include "servo.h"
#include <stdint.h>
#include <stdbool.h>
#include <inc/tm4c123gh6pm.h>
#include "driverlib/interrupt.h"
#include "button.h"

#include "Timer.h"
#include "button.h"
#include "lcd.h"



int ANGLE;
/*
 * this method is used to initallize the servo motor for the cybot that is used to scan
 */
void servo_init(void)
{
    SYSCTL_RCGCGPIO_R |= 0x02;
    while ((SYSCTL_PRGPIO_R & 0x02) == 0)
    {
    };
    SYSCTL_RCGCTIMER_R |= 0x02;
    while ((SYSCTL_PRTIMER_R & 0x02) == 0)
    {
    };
    GPIO_PORTB_DEN_R |= 0x20;
    GPIO_PORTB_DIR_R |= 0x20;

    GPIO_PORTB_AFSEL_R |= 0x20;
    GPIO_PORTB_PCTL_R = (GPIO_PORTB_PCTL_R & ~0x00700000) | 0x00700000;

    TIMER1_CTL_R &= ~(0x100);
    TIMER1_CFG_R = 0x00000004;
    TIMER1_TBMR_R |= 0b1010;
    TIMER1_CTL_R &= 0xBFFF;
    TIMER1_TBPR_R |= 0x4;
    TIMER1_TBILR_R |= 0xE200;
    TIMER1_TBMATCHR_R = 0xA90E;
    TIMER1_TBPMR_R = 0x4;
    TIMER1_CTL_R |= 0x100;

    ANGLE = 90;

}

void servoMove(uint16_t degrees)
{
    int leftBound = 291022;//0 degrees

    int rightBound = 319822;// 180 degrees

    uint32_t lowPulse = rightBound - ((rightBound - leftBound) / 180) * degrees;

    TIMER1_TBMATCHR_R = (lowPulse & 0xFFFF);
    ANGLE = degrees;
}


