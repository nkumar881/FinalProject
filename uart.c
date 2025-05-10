/*
 * button.c
 *
 * @author Mitch Folwer, Nikhil Kumar, Adam, Brandon Beaver
 */



//The buttons are on PORTE 3:0
// GPIO_PORTE_DATA_R -- Name of the memory mapped register for GPIO Port E,
// which is connected to the push buttons
#include "button.h"


/**
 * Initialize PORTE and configure bits 0-3 to be used as inputs for the buttons.
 */
void button_init() {
	static uint8_t initialized = 0;

	//Check if already initialized
	if(initialized){
		return;
	}

	SYSCTL_RCGCGPIO_R |= 0b10000;//initalizes the clock 100000 for port e
	while ((SYSCTL_PRGPIO_R & 0x10) == 0) //hex for port e
	{
	    long delay = SYSCTL_RCGCGPIO_R;
	}
	GPIO_PORTE_DIR_R &=0b11110000;//bitwise and to mask last 4 bits to 0(active low for the switches)
	GPIO_PORTE_DEN_R |=0b00001111;//bitwise or to mask them to 1 whichis off (first 4 bits remain the same)
	initialized = 1;
}



/**
 * Returns the position of the rightmost button being pushed.
 * @return the position of the rightmost button being pushed. 1 is the leftmost button, 4 is the rightmost button.  0 indicates no button being pressed
 */
uint8_t button_getButton() {

	// INSERT CODE HERE!

    if((GPIO_PORTE_DATA_R & 0b00001000) == 0b00000000)
    {
        return 4;
    }
    if((GPIO_PORTE_DATA_R & 0b00000100) == 0b00000000)
       {
           return 3;
       }

    if((GPIO_PORTE_DATA_R & 0b00000010) == 0b00000000)
       {
           return 2;
       }

    if((GPIO_PORTE_DATA_R & 0b00000001) == 0b00000000)
       {
           return 1;
       }

	return 0; // EDIT ME
}
