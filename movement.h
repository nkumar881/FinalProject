/*
 * movement.h
 *
 *  Created on: Feb 7, 2025
 *      Author: msfowler
 */


#ifndef HEADER_FILE
#define HEADER_FILE


//function headers and macro definitions

double  move_forward (oi_t  *sensor_data,   double distance_mm);
double move_backward (oi_t *sensor_data, double distance_mm);
double turn_right (oi_t *sensor, double degrees);
double turn_left (oi_t *sensor, double degrees);
void moveForwardPart3(oi_t *sensor_data, double distance_mm);
#endif
