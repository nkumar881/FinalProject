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


int DIR;
int ANGLE;

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
    DIR = 0;
}

void servo_move(uint16_t degrees)
{
    int leftBound = 291022;

    int rightBound = 319822;

    uint32_t lowPulse = rightBound - ((rightBound - leftBound) / 180) * degrees;

    TIMER1_TBMATCHR_R = (lowPulse & 0xFFFF);
    TIMER1_TBPMR_R = (lowPulse >> 16);
    ANGLE = degrees;
}

void button_move(void)
{
    int temp = 0;
    while (temp == 0)
    {
        temp = button_getButton();
        timer_waitMillis(100);
    }
    if (temp == 1)
    {
        if (DIR == 0)
        {
            if (ANGLE >= 179)
            {
                servo_move(180);
            }
            else
            {
                ANGLE += 1;
                servo_move(ANGLE);
            }
        }
        else
        {
            if (ANGLE <= 1)
            {
                servo_move(0);
            }
            else
            {
                ANGLE -= 1;
                servo_move(ANGLE);
            }
        }
    }
    else if (temp == 2)
    {
        if (DIR == 0)
        {
            if (ANGLE >= 175)
            {
                servo_move(180);
            }
            else
            {
                ANGLE += 5;
                servo_move(ANGLE);
            }
        }
        else
        {
            if (ANGLE <= 5)
            {
                servo_move(0);
            }
            else
            {
                ANGLE -= 5;
                servo_move(ANGLE);
            }
        }
    }
    else if (temp == 3)
    {
        if (DIR == 0)
        {
            DIR = 1;
        }
        else
        {
            DIR = 0;
        }
    }
    else if (temp == 4)
    {
        if (DIR == 0)
        {
            servo_move(175);
        }
        else
        {
            servo_move(5);
        }
    }
    temp = 0;
    char ang[10];
    sprintf(ang, "%d", ANGLE);
    lcd_printf(ang);
}

void calibrate(void)
{
    int x = 0;
    uint32_t value;
    uint32_t value2;

    TIMER1_TBMATCHR_R = 0xE200;
    TIMER1_TBPMR_R = 0x4;
    int count = 0;
    char array[40];
    lcd_printf(
            "Button1: move left\nButton2: move right\nButton3: get value1\nButton4: get value2");
    while (x == 0)
    {
        int y = 0;
        while (y == 0)
        {
            y = button_getButton();
            timer_waitMillis(100);
        }
        if (y == 1)
        {
            count++;
            servo_move(count);
        }
        else if (y == 2)
        {
            count--;
            servo_move(count);
        }
        else if (y == 3)
        {
            value = TIMER1_TBMATCHR_R;
            value += 262144;
            sprintf(array, "Value 1: %d\n", value);
            lcd_printf(array);
        }
        else if (y == 4)
        {
            value2 = TIMER1_TBMATCHR_R;
            value2 += 262144;
            sprintf(array, "Value 1: %d\nValue 2: %d", value, value2);
            lcd_printf(array);
            x = 1;
        }
    }
}

