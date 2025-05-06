/*
 * movement.c
 *
 *  Created on: Feb 7, 2025
 *      Author: msfowler
 */
#include "open_interface.h"
#include "Timer.h"
#include "lcd.h"

double move_forward(oi_t *sensor_data, double distance_mm)
{
    double sum = 0; // distance member in oi_t struct is type double
    oi_setWheels(250, 250); //move forward at full speed
    while (sum < distance_mm)
    {
        oi_update(sensor_data);
        sum += sensor_data->distance; // use -> notation since pointer
        //lcd_printf("%lfmm", sum); //uncomment for part 1 of the demo
    }
    oi_setWheels(0, 0); //stop

    return sum;
}

double move_backward(oi_t *sensor_data, double distance_mm)
{
    double sum = 0;
    oi_setWheels(-250, -250);
    distance_mm *= -1;
    while (sum > distance_mm)
    {
        oi_update(sensor_data);
        sum += sensor_data->distance;
        //lcd_printf("%lfmm", sum);
    }
    oi_setWheels(0, 0);

    return sum;
}

void turn_right(oi_t *sensor, double degrees)
{
    double sum = 0;
    //degrees *= -1;
    oi_setWheels(-100, 100);
    while (sum > degrees)
    {
        oi_update(sensor);
        sum += sensor->angle;

    }
    oi_setWheels(0, 0);
}

void turn_left(oi_t *sensor, double degrees)
{
    double sum = 0;
    oi_setWheels(+100, -100);
    while (sum < degrees)
    {
        oi_update(sensor);
        sum += sensor->angle;
    }
    oi_setWheels(0, 0);
}

void moveForwardPart3(oi_t *sensor_data, double distance_mm)
{
    double distanceTravelled = 0;
    oi_setWheels(100, 100); //set to be slow for testing

    while (distanceTravelled < distance_mm)
    {
        oi_update(sensor_data); //update the data first
        distanceTravelled += sensor_data->distance; //get the distance first

        //lcd_printf("%lf",&distanceTravelled);

        //check for bumper right
        if (sensor_data->bumpRight) // looks like if it bumps then the value is returned as 1
        {


            oi_setWheels(0, 0);
            move_backward(sensor_data, 150);
            distanceTravelled-=150;
            turn_left(sensor_data, 85);
            move_forward(sensor_data, 250);
            turn_right(sensor_data, -87); //maybe look to modify the turn right to make sure i dont have to use -90
            oi_setWheels(100, 100);

        }

        //check for bumper left

        if (sensor_data->bumpLeft)
        {
            oi_setWheels(0, 0);
            move_backward(sensor_data, 150);
            distanceTravelled-=150;
            turn_right(sensor_data, -85);
            move_forward(sensor_data, 250);
            turn_left(sensor_data, 87); //maybe look to modify the turn right to make sure i dont have to use -90
            oi_setWheels(100, 100);
        }
    }
    oi_setWheels(0, 0);

}
