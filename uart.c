/**
 *  @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 */

#include "Timer.h"
#include "lcd.h"
#include "ping.h"
//#include "uart-interrupt.h"
#include "uart.h"
#include "driverlib/interrupt.h"
#include "open_interface.h"
#include "movement.h"
#include "string.h"
#include "stdio.h"
#include <math.h>
#include "adc.h"
#include "servo.h"

void scan();
void play_mario_theme();
void printGui(char gui[34][16]);
typedef struct
{
    int startAngle;
    int endAngle;
    int midPoint;
    int angularWidth;
    float irDistance;
    float pingDistance;
    float width;
} objects;
int main(void)
{
    timer_init(); // Must be called before lcd_init(), which uses timer functions
    lcd_init();
    adc_init();
    ping_init();
    servo_init();
    lcd_clear();
    oi_t *sensor = oi_alloc();
    oi_init(sensor);
    uart_init();

    objects obj[10];
    while (1)
    {
        char c = uart_receive();
        if (c == 't')
        {

            scan(obj);

        }
        if (c == 'w')
        {
            move_forward(sensor, 20);
        }
        if (c == 'a')
        {
            turn_left(sensor, 2);
        }
        if (c == 's')
        {
            move_backward(sensor, 20);
        }
        if (c == 'd')
        {
            turn_right(sensor, -2);
        }
        if (c == 'm')
        {
            play_mario_theme();
        }
    }

}

void scan(objects obj[10])
{
    //get the first ir and ping values
    servoMove(0);
    int raw1 = adc_read_avg(16);
    float lastDistIr = pow((8360.8 / raw1), (1 / 0.562));
    int flag = 0;
    int startAngle;
    int objCount = 0;

    char toPrint[200];
    int i = 0;

    //remove before submitting
    sprintf(toPrint, " %f \r\n", lastDistIr);
    uart_sendStr1(toPrint);

    // this is for printing out onto the screen

    char gui[34][16];
    int c, r;
    for (r = 0; r < 16; r++)
    {
        for (c = 0; c < 34; c++)
        {
            gui[c][r] = '.';
        }

    }

    char str[50];

    for (i = 0; i < 180; i += 2)
    {
        servoMove(i);

        int sumRaw = 0;
        int k = 0;
        for (k = 0; k < 3; k++)
        {
            int raw = adc_read_avg(16);
            sumRaw += raw;
        }
        sumRaw /= 3;

        //float dist = pow((8360.8 / sumRaw), (1 / 0.562)); //change the formula to suit the bot
        float dist = 9601912.4896 * pow(sumRaw, -1.7560);
        float distance = ping_getDistance(); //same for this

        sprintf(toPrint, "%d \t %f \t %f \r\n", i, dist, distance);
        uart_sendStr1(toPrint);

        if (i <= 90)
        {
            int col, row;
            float x, y;
            float angleRad = i * (M_PI / 180.0);
            if (dist >= 60)
                dist = 60;
            x = dist * cos(angleRad);
            y = dist * sin(angleRad);
            x /= 5;
            y /= 5;
            col = 16 + (floor(x));
            row = floor(y);
//
            if (col >= 0 && col < 34 && row >= 0 && row <= 16)

                gui[col][row] = 'X';

        }
        else
        {
            int col, row;
            float x, y;
            float angleRad = (180 - i) * (M_PI / 180.0);
            if (dist >= 60)
                dist = 60;
            x = dist * cos(angleRad);
            y = dist * sin(angleRad);
            x /= 10;
            y /= 10;
            col = (floor(x));
            row = floor(y);
//            if (col >= 0 && col <= 16 && row >= 0 && row < 16)
//
            gui[col][row] = 'X';
            //}
        }

        if (dist > 2 && dist < 50 && lastDistIr < 180) //change the last dist ir to a very large value or dont check only
        {
            if (flag == 0 && (lastDistIr - dist) >= 5) //arbitarily 5 for now... can change later
            {
                flag = 1;
                startAngle = i;
                obj[objCount].startAngle = i;
                sprintf(str, "There is an object at %d\n\r", startAngle);
                uart_sendStr1(str);

            }
        }

        if ((flag == 1 && (dist - lastDistIr) >= 5 && dist > 45)
                || (flag == 1 && dist > 55)
                || (flag == 1 && dist - lastDistIr >= 15)) //dist above 45 might have cooked or if difference is above 15 then that immeadiately means end
        {
            flag = 0;
            obj[objCount].endAngle = i;
            obj[objCount].angularWidth = i - startAngle;
            obj[objCount].midPoint = (obj[objCount].startAngle
                    + obj[objCount].endAngle) / 2;
            servoMove(obj[objCount].midPoint);
            int d = ping_getDistance();

            obj[objCount].irDistance = d;         //see if average is needed
            float halfAngleinRad = (obj[objCount].angularWidth * (M_PI / 180.0))
                    / 2.0;
            float linearWidth = halfAngleinRad * tan(halfAngleinRad) * 100; //times 100 in cm
            obj[objCount].width = linearWidth;
            objCount++;
            sprintf(str,
                    "The object ends here %d %d is the mid angle and %f for width\n\r",
                    i, obj[objCount - 1].midPoint, linearWidth);
            uart_sendStr1(str);
        }
        lastDistIr = dist;
        timer_waitMillis(300);
    }

    int validCount = 0;
    for (i = 0; i < objCount; i++)
    {
        if (obj[i].angularWidth >= 5)
        {
            obj[validCount] = obj[i];
            validCount++;
        }
    }
    objCount = validCount;  // Update the count to only include valid objects

    sprintf(str, "There are %d objects\n\r", objCount);
    uart_sendStr1(str);

    printGui(gui);

    for (i = 0; i < validCount; i++)
    {
        int midPoint1;
        float dist1;
        midPoint1 = obj[i].midPoint;
        dist1 = obj[i].irDistance;
        float width = obj[i].width;
        sprintf(str, "Angle: %d dist: %lf width: %lf\n\r", midPoint1, dist1,
                width);
        uart_sendStr1(str);
    }
}

void play_mario_theme()
{
    unsigned char notes[] = { 76, 76, 0, 76, 0, 72, 76, 0, 79, 0, 67 };
    unsigned char durations[] = { 12, 12, 6, 12, 6, 12, 12, 6, 12, 6, 24 };
    oi_loadSong(0, sizeof(notes), notes, durations);
    oi_play_song(0);
}

void printGui(char gui[34][16])
{
    int i, j;
    uart_sendChar1('+');
    for (j = 0; j < 34; j++)
        uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");

    for (i = 15; i >= 0; i--)
    {
        uart_sendChar1('|');
        for (j = 0; j < 34; j++)
        {
            uart_sendChar1(gui[j][i]);
        }
        uart_sendChar1('|');
        uart_sendStr1("\n\r");
    }

    uart_sendChar1('+');
    for (j = 0; j < 34; j++)
        uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");
}
