
**** Build of configuration Debug for project Lab10 ****

"C:\\ti\\ccs1271\\ccs\\utils\\bin\\gmake" -k -j 20 all -O 
 
Building file: "../main.c"
Invoking: Arm Compiler
"C:/ti/ccs1271/ccs/tools/compiler/ti-cgt-arm_20.2.7.LTS/bin/armcl" -mv7M4 --code_state=16 --float_support=FPv4SPD16 -me --include_path="C:/ti/TivaWare_C_Series-2.2.0.295" --include_path="U:/CprE288Workspace/Lab10" --include_path="C:/ti/ccs1271/ccs/tools/compiler/ti-cgt-arm_20.2.7.LTS/include" --define=ccs="ccs" --define=PART_TM4C123GH6PM -g --gcc --diag_warning=225 --diag_wrap=off --display_error_number --abi=eabi --preproc_with_compile --preproc_dependency="main.d_raw"  "../main.c"
 
>> Compilation failure
subdir_rules.mk:9: recipe for target 'main.obj' failed
"../main.c", line 259: warning #169-D: argument of type "char (*)[16]" is incompatible with parameter of type "char (*)[8]"
"../main.c", line 273: error #148: declaration is incompatible with "void printGui(char (*)[8])" (declared at line 25)
1 error detected in the compilation of "../main.c".
gmake: *** [main.obj] Error 1
gmake: Target 'all' not remade because of errors.

**** Build Finished ****


/**
 * @file lab9_template.c
 * @author
 * Template file for CprE 288 Lab 9
 */

#include "Timer.h"
#include "lcd.h"
#include "ping.h"
//#include "uart-interrupt.h"
#include "uart.h"
#include "driverlib/interrupt.h"
#include "open_interface.h"
#include "movement.h"
#include "cyBot_Scan.h"
#include "string.h"
#include "stdio.h"
#include <math.h>
#include "adc.h"
#include "servo.h"

// Uncomment or add any include directives that are needed
void scan();
void play_mario_theme();
void printGui(char gui[17][8]);
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
            // lcd_printf("heleo");
            // uart_sendChar1(c);
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
//calibrate the ir sensors whenever possible
//pass the array of objects into this for auto updation
//make sure that ir range detection is less than 50 cm, else not accurate
//calibrate the sensors so that they spit close to the same value
//account for the size of the bot as well

void scan(objects obj[10])
{
    //get the first ir and ping values
    servo_move(0);
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
    int c,r;
    for (r = 0; r < 16; r++)
        {
            for (c = 0; c < 34; c++)
            {
                gui[c][r]='.';
            }

        }
    //max ping to be set at 80

    char str[50];

    for (i = 0; i < 180; i += 2)
    {
        servo_move(i);

        int sumRaw = 0;
        int k = 0;
        for (k = 0; k < 3; k++)
        {
            int raw = adc_read_avg(16);
            sumRaw += raw;
        }
        sumRaw /= 3;

        float dist = pow((8360.8 / sumRaw), (1 / 0.562)); //change the formula to suit the bot

        float distance = ping_getDistance(); //same for this

        sprintf(toPrint, "%d \t %f \t %f \r\n", i, dist, distance);
        uart_sendStr1(toPrint);

        //this is the code to generate the scan field
        //could switch out ping for ir if needss be

        //start with if i<=90 and then i>=90
        if (i <= 90)
        {
            int col, row;
            float x, y;
            float angleRad = i * (M_PI / 180.0);
            if (dist >= 80)
                dist = 80;
            x = dist * cos(angleRad);
            y = dist * sin(angleRad);
            x /= 5;
            y /= 5;
            col = 16 + (floor(x));
            row = floor(y);
//            if (row < 0)
//                row = 0;
//            if (row > 7)
//                row = 7;
//            if (col < 0)
//                col = 0;
//            if (col > 16)
//                col = 16;
           if(col>=0 && col<=16 && row >=0 && row<=16)
               gui[col][row]='X';

        }
        else
        {
            int col, row;
            float x, y;
            float angleRad = (180 - i) * (M_PI / 180.0);
            if (dist >= 80)
                dist = 80;
            x = dist * cos(angleRad);
            y = dist * sin(angleRad);
            x /= 10;
            y /= 10;
            col = (floor(x));
            row = floor(y);
//            if (row < 0)
//                            row = 0;
//                        if (row > 7)
//                            row = 7;
//                        if (col < 0)
//                            col = 0;
//                        if (col > 16)
//                            col = 16;
//            if (flag == 1)
//                gui[col][row] = 'X';
//            else
//                gui[col][row] = ' ';
            if(col>=0 && col<=16 && row >=0 && row<=16)
                           gui[col][row]='X';

        }

        //and this should potentially be enough to print out the gui
        //after the scan is done can call a method that prints it out

        //  lcd_printf("%d %f cm %f cm\r\n", sumRaw, dist, distance);
        //removve these, these are just test cases

        if (dist > 2 && dist < 55 && lastDistIr < 180) //change the last dist ir to a very large value or dont check only
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
                || (flag == 1 && dist > 55)) //dist above 45 might have cooked or if difference is above 15 then that immeadiately means end
        {
            flag = 0;
            obj[objCount].endAngle = i;
            obj[objCount].angularWidth = i - startAngle;
            obj[objCount].midPoint = (obj[objCount].startAngle
                    + obj[objCount].endAngle) / 2;
            servo_move(obj[objCount].midPoint);
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
}
//calibrate the 2 sensors accordingly
//just added the formula for now.

//for the simple gui....when flag is 1 take the angle and ping distance scan....
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
    for (j = 0; j < 34; j++) uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");

    for (i = 15; i >= 0; i--)  // optional: print from top to bottom
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
    for (j = 0; j < 34; j++) uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");
}
