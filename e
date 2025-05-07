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
    int raw1=adc_read_avg(16);
    float lastDistIr=pow((8360.8 / sumRaw), (1 / 0.562));
    int flag = 0;
    int startAngle;
    int objCount=0;

     char toPrint[200];
     int i = 0;


char str[50];

     for (i = 0; i < 180; i += 2)
     {
         servo_move(i);
 
         int sumRaw=0;
         int k=0;
         for(k=0;k<3;k++)
         {
             int raw = adc_read_avg(16);
             sumRaw+=raw;
         }
         sumRaw/=3;
 
         float dist = pow((8360.8 / sumRaw), (1 / 0.562));
 
         float distance = ping_getDistance();
 
         sprintf(toPrint, "%d \t %f \t %f \r\n", sumRaw, dist, distance);
         uart_sendStr1(toPrint);
 
 
         lcd_printf("%d %f cm %f cm\r\n", sumRaw, dist, distance);
         //removve these, these are just test cases
         

         if(dist>2 && dist<55 && lastDistIr<60)
         {
            if(flag==0 && (dist-lastDistIr)>=5)//arbitarily 5 for now... can change later
            {
                flag=1;
                startAngle=i;
                obj[objCount].startAngle=i;
                sprintf(str, "There is an object at %d\n\r", startAngle);
            uart_sendStr1(str);

            }
         }
         if((flag==1 && (lastDistIr-dist)>=5 && dist >45)||(flag==1 && dist>55))
         {
            flag = 0;
            obj[objCount].endAngle=i;
            obj[objCount].angularWidth=i-startAngle;
            obj[objCount].midPoint=(obj[objCount].startAngle+obj[objCount].endAngle)/2;
            servo_move(obj[objCount].midPoint);
            int d=ping_getDistance();

            obj[objCount].distanceVal=d;//see if average is needed
            float halfAngleinRad=(obj[objCount].angularWidth * (M_PI/180.0))/2.0;
            float linearWidth=halfAngleinRad * tan(halfAngleinRad)*1000;
            obj[objCount].width=linearWidth;
            objCount++;
            sprintf(str, "The object ends here %d %d is the mid angle and %f for width\n\r", i,obj[objCount-1].midPoint, linearWidth);
            uart_sendStr1(str);
         }
         astIr = avgIr;
         timer_waitMillis(300);
     }

     int validCount = 0;
    for ( i = 0; i < objCount; i++) {
        if (obj[i].angularWidth >= 5) {
            obj[validCount] = obj[i];
            validCount++;
        }
    }
    objCount = validCount;  // Update the count to only include valid objects

    sprintf(str, "There are %d objects\n\r", objCount);
                uart_sendStr1(str);
 }
 //calibrate the 2 sensors accordingly
 //just added the formula for now.
