 11.216113
0        11.160607       14.173404
2        44.303574       50.488525
4        133.601837      50.229134
6        64.505081       50.224846
8        46.359974       50.073711
There is an object at 8
10       45.602810       50.071568
12       50.849335       49.640675
The object ends here 12 10 is the mid angle and 0.121896 for width
14       49.124237       50.043701
16       65.663139       50.205551
18       119.331108      50.547482
20       120.838493      50.932289
22       108.261032      51.404984
24       81.496040       50.612865
26       66.553146       49.815392
28       51.146042       42.608105
There is an object at 28
30       45.190472       42.332630
32       44.622913       39.600422
34       46.359974       42.798893
36       32.838844       43.209423
38       24.858927       77.167496
40       23.182076       77.576950
42       21.597687       82.381096
44       20.553377       94.767685
46       19.409630       314.557800
48       17.737549       314.668182
50       17.002174       314.446320
52       16.280045       314.434540
54       15.745690       315.133392
56       15.104264       315.104431
58       14.475031       32.022266
60       14.095661       315.126953
62       13.655494       27.977011
64       13.200416       16.504732
66       12.768591       16.026676
68       12.283151       16.444706
70       12.113745       15.958076
72       11.795732       15.462870
74       11.558392       15.011608
76       11.597427       14.551775
78       11.356779       14.209847
80       11.179062       14.191625
82       10.996639       14.194840
84       11.234711       14.192696
86       11.385243       14.164827
88       11.375743       14.187338
90       11.197563       14.198056
92       11.253357       14.170188
94       11.253357       14.162685
96       11.413819       14.164827
98       11.577884       14.499253
100      11.529249       14.542129
102      11.755650       14.544272
104      11.866392       15.011608
106      12.261773       15.035192
108      12.610929       15.522894
110      12.940957       15.997735
112      13.188447       16.877743
114      13.834104       41.337933
116      14.189035       40.886669
118      14.870593       54.652763
120      15.511806       52.704090
122      16.115164       53.479057
124      16.755999       53.923885
126      16.931265       53.040661
128      18.523838       51.712608
130      19.787104       50.217342
132      21.215393       49.288029
134      22.671444       49.021130
136      23.532551       47.940681
138      26.411722       47.526939
140      28.636173       47.351151
142      29.753239       47.886017
144      31.962408       48.105751
146      36.690445       48.218300
148      38.726139       48.165779
150      41.297222       48.547363
152      40.664673       27.968433
154      42.386181       27.882683
156      40.943924       25.250160
158      44.383072       24.305838
160      26.411722       23.936039
162      19.809664       23.918890
164      18.523838       23.979988
166      19.022074       23.382954
168      19.742102       23.408678
170      32.938538       23.411892
172      66.254395       23.450481
The object ends here 172 100 is the mid angle and 386.753174 for width
174      12.544289       14.522834
176      20.316345       23.396887
178      72.999741       23.409752
There are 1 objects
+----------------------------------+
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|..................................|
|.......................X..........|
|.......................X..........|
|...................X.X............|
|...X...........XXXXX.....X........|
|XXXXX...................X.........|
|.XXX..X...........................|
+----------------------------------+
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
            if(flag==1){
           if(col>=0 && col<34 && row >=0 && row<=16)
               gui[col][row]='X';
            }
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
            if(flag==1){
            if(col>=0 && col<=16 && row >=0 && row<=16)
                           gui[col][row]='X';
            }
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

