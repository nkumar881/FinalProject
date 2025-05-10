/**
 * Driver for ping sensor
 * @file ping.c
 * @author
 */

#include "ping.h"
#include "Timer.h"

// Global shared variables
// Use extern declarations in the header file

extern volatile uint32_t g_start_time = 0;
extern volatile uint32_t g_end_time = 0;
volatile enum{LOW, HIGH, DONE} g_state = LOW; // State of ping echo pulse
volatile char interrupt_flag;
volatile unsigned int dif_time;
volatile unsigned int overflow = 0;

void ping_init (void){

  // YOUR CODE HERE
  //enable clock to GPIO port B
  SYSCTL_RCGCTIMER_R |= 0x08;
  SYSCTL_RCGCGPIO_R |= 0x02;

  while ((SYSCTL_PRTIMER_R & 0x08) == 0) {};
  while ((SYSCTL_PRGPIO_R & 0x02) == 0) {};

  // activate ILR and PLR registers
  TIMER3_TBILR_R |= 0xFFFF;
  TIMER3_TBPR_R |= 0xFF;

  GPIO_PORTB_DIR_R &= ~0x08;
  GPIO_PORTB_DEN_R |= 0x08; // Only PB3
  GPIO_PORTB_AFSEL_R |= 0x08;
  GPIO_PORTB_PCTL_R = (GPIO_PORTB_PCTL_R & ~0x0000F000) | 0x00007000; // Clear PCTL bits for PB3

  TIMER3_CTL_R &= ~0x100;
  TIMER3_CFG_R = 0x04;
  TIMER3_TBMR_R = 0x07;
  TIMER3_CTL_R |= 0x0C00;
  TIMER3_IMR_R |= 0x400;
  TIMER3_ICR_R |= 0x400;

  NVIC_PRI9_R = (NVIC_PRI9_R & 0xFFFFFF00) | 0x20;
  NVIC_EN1_R = (1 << (INT_TIMER3B - 48));

    IntRegister(INT_TIMER3B, TIMER3B_Handler);

    IntMasterEnable();

    // Configure and enable the timer
    TIMER3_CTL_R |= 0x100;
}

void ping_trigger (void){
    g_state = LOW;
    // Disable timer and disable timer interrupt
    TIMER3_CTL_R &= ~0x100;
    TIMER3_IMR_R &= ~0x400;
    // Disable alternate function (disconnect timer from port pin)
    GPIO_PORTB_AFSEL_R &= ~0x08;

    // YOUR CODE HERE FOR PING TRIGGER/START PULSE
    GPIO_PORTB_DIR_R |= 0x08;
    GPIO_PORTB_DATA_R &= ~0x08;
    GPIO_PORTB_DATA_R |= 0x08;
    timer_waitMicros(5);
    GPIO_PORTB_DATA_R &= ~0x08;


    // Clear an interrupt that may have been erroneously triggered
    GPIO_PORTB_DIR_R &= ~0x08;
    GPIO_PORTB_AFSEL_R |= 0x08;
    TIMER3_ICR_R |= 0x400;
    // Re-enable alternate function, timer interrupt, and timer
    TIMER3_IMR_R |= 0x400;
    TIMER3_CTL_R |= 0x100;
}

void TIMER3B_Handler(void){

  // YOUR CODE HERE
  // As needed, go back to review your interrupt handler code for the UART lab.
  // What are the first lines of code in the ISR? Regardless of the device, interrupt handling
  // includes checking the source of the interrupt and clearing the interrupt status bit.
  // Checking the source: test the MIS bit in the MIS register (is the ISR executing
  // because the input capture event happened and interrupts were enabled for that event?
  // Clearing the interrupt: set the ICR bit (so that same event doesn't trigger another interrupt)
  // The rest of the code in the ISR depends on actions needed when the event happens.

    if (TIMER3_MIS_R & 0x400) {

        TIMER3_ICR_R = 0x400;

        if (g_state == LOW) {

            g_start_time = TIMER3_TBR_R;
            g_state = HIGH;
        }
        else if (g_state == HIGH) {

            g_end_time = TIMER3_TBR_R;
            g_state = DONE;
        }

    }

}

float ping_getDistance (void){

    // YOUR CODE HERE
    float cm = 0;
        double period = 0.0000000625;                // 1/f = 1/16e6
        double time = 0;
        g_state = LOW;
        ping_trigger();                               // Sends pulse
        while (g_state != DONE) {}      // Wait for ISR to capture rising and falling edge time

        if (g_start_time < g_end_time)
        {
            dif_time = g_start_time - g_end_time;       // Clocks per cycle
            overflow++;
        }
        else                                        // Overflow
        {
            //dif_time = (65535 - fall_time) + rise_time; // Max val - fall, + rise
            dif_time = g_start_time - g_end_time;
        }

        time = dif_time * period;                   // Calculate time elapsed in seconds (for demo 3 would just need to divide by 1000 and print to LCD)
        cm = (time / 2) * 34000.0;                  // Divide by 2 bc sound goes there and back, then *34000 because speed in cm/s (time/2 * speed)

        return cm;

}
