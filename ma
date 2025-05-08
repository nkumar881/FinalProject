void printGui(char gui[17][8])
{
    int i, j;
    uart_sendChar1('+');
    for (j = 0; j < 17; j++) uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");

    for (i = 7; i >= 0; i--)  // optional: print from top to bottom
    {
        uart_sendChar1('|');
        for (j = 0; j < 17; j++)
        {
            uart_sendChar1(gui[j][i]);
        }
        uart_sendChar1('|');
        uart_sendStr1("\n\r");
    }

    uart_sendChar1('+');
    for (j = 0; j < 17; j++) uart_sendChar1('-');
    uart_sendChar1('+');
    uart_sendStr1("\n\r");
}
