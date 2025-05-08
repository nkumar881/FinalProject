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


 137.238831
0        137.704315      94.706589
2        134.496841      98.103363
4        131.839478      114.615593
6        122.764954      116.436707
8        124.739807      115.489174
10       95.735085       115.202988
12       118.588402      114.925369
14       99.835098       114.973595
16       91.152466       114.596306
18       67.309296       114.343330
20       95.735085       114.614525
22       81.290756       114.093590
24       81.086281       114.631676
26       86.001266       114.585587
28       124.340889      114.631676
30       130.971878      98.238411
32       101.552361      71.293625
34       130.541428      70.809135
36       132.716080      69.898041
38       133.157806      69.269928
40       133.157806      69.219543
42       132.716080      68.803658
44       68.862442       68.929062
46       67.769447       68.882973
48       71.466629       68.874397
50       70.636520       68.903336
52       109.555092      68.803658
54       132.716080      68.854034
56       129.263214      68.717911
58       134.947876      68.730766
60       125.948647      69.185242
62       103.614830      69.224907
64       106.676750      69.794067
66       125.948647      70.565819
68       135.857040      98.442070
70       135.857040      140.752182
72       135.401260      141.027664
74       135.857040      141.594681
76       80.075836       140.575333
78       73.347404       151.102219
80       71.634483       141.622559
82       86.450539       135.525742
84       123.548996      135.918030
86       134.048172      106.638695
88       129.687103      105.923759
90       133.601837      135.332794
92       135.857040      134.633942
94       133.157806      134.690750
96       126.764740      99.204178
98       136.315216      99.117355
100      136.775803      98.697182
102      136.775803      98.390617
104      136.775803      98.283432
106      137.238831      97.612442
108      137.238831      97.771080
110      137.238831      97.503113
112      137.238831      97.299454
114      97.888306       97.264084
116      66.105804       97.064713
118      68.862442       97.046494
120      69.660110       27.806580
122      133.601837      28.130287
124      138.642715      25.014347
126      139.591141      23.706659
128      139.591141      23.230747
130      27.621172       22.933838
There is an object at 130
132      21.115231       22.934910
134      19.365963       22.246765
136      18.605453       22.244621
138      17.235865       21.771925
140      17.073549       21.751558
142      17.437546       21.759064
144      17.363783       21.764421
146      17.181494       21.790146
148      17.382177       21.804081
150      17.737549       21.820160
152      18.045692       22.303576
154      17.456062       22.283209
156      19.022074       22.291784
158      86.225449       22.925262
The object ends here 158 144 is the mid angle and 6.092233 for width
160      17.037804       21.777285
162      65.957733       23.705587
164      64.505081       28.150654
166      66.105804       28.566542
168      89.224846       94.336792
170      133.157806      94.159935
172      139.115662      94.716240
174      139.115662      94.711945
176      138.642715      94.731239
178      138.642715      94.904884
There are 1 objects
+----------------------------------+
|................X.................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|XXXX..............................|
|...XX.............................|
|..X...............................|
|..................................|
|..................................|
|.X....XX..........................|
|.X....XX..........................|
|.X.....X........X.................|
+----------------------------------+
0 to 90 is on the right

