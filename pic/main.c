#include "p32xxxx.h"
#include <stdio.h>

#define BUFSIZE 30

typedef struct {
    unsigned char i;
    signed long int v:24;
} pairdata_t;

typedef struct {
    union {
        pairdata_t data;
        long l;
    } pair1;
    union {
        pairdata_t data;
        long l;
    } pair2;
} xcorrdata_t;

void initUART(void)
{
    // Configure UART
    // Using UART2

    TRISFbits.TRISF5 = 1; // RF5 is UART6 TX (output)
    TRISFbits.TRISF4 = 0; // RF4 is UART6 RX (input)

    // Want rate of 115.2 Kbaud
    // Assuming PIC peripheral clock Fpb = Fosc / 2 = 20 MHz
    // based on default instructions in lab 1.
    // U6BRG = (Fpb / 4*baud rate) - 1
    // -> U6BRG = 10 (decimal)
    // Actual baud rate 113636.4 (-1.2% error)
    U2BRG = 10;

    // UART2 Mode Register
    // bit 31-16: unused
    // bit 15:	ON = 1: enable UART
    // bit 14:	FRZ = 0: don't care when CPU in normal state
    // bit 13:	SIDL = 0: don't care when CPU in normal state
    // bit 12:	IREN = 0: disable IrDA
    // bit 11:	RTSMD = 0: don't care if not using flow control
    // bit 10:	unused
    // bit 9-8: UEN = 00: enable U1TX and U1RX, disable U1CTSb and U1RTSb
    // bit 7:	WAKE = 0: do not wake on UART if in sleep mode
    // bit 6:	LPBACK = 0: disable loopback mode
    // bit 5:	ABAUD = 0: don't auto detect baud rate
    // bit 4:	RXINV = 0: U1RX idle state is high
    // bit 3:	BRGH = 0: standard speed mode
    // bit 2-1: PDSEL = 00: 8-bit data, no parity
    // bit 0: 	STSEL = 0: 1 stop bit
    U2MODE = 0x8000;

    // UART2 Status and control register
    // bit 31-25: unused
    // bit 13: UTXINV = 0: U1TX idle state is high
    // bit 12: URXEN = 1: enable receiver
    // bit 11: UTXBRK = 0: disable break transmission
    // bit 10: UTXEN = 1: enable transmitter
    // bit 9: UTXBF: don't care (read-only)
    // bit 8: TRMT: don't care (read-only)
    // bit 7-6: URXISEL = 00: interrupt when receive buffer not empty
    // bit 5: ADDEN = 0: disable address detect
    // bit 4: RIDLE: don't care (read-only)
    // bit 3: PERR: don't care (read-only)
    // bit 2: FERR: don't care (read-only)
    // bit 1: OERR = 0: reset receive buffer overflow flag
    // bit 0: URXDA: don't care (read-only)
    U2STA = 0x1400;
}

void putcharserial(char c)
{
    while (U2STAbits.UTXBF); // wait until transmit buffer empty
    U2TXREG = c;		// transmit character over serial port
}

void putstrserial(char *str)
{
    int i = 0;
    while (str[i] != 0) {
        putcharserial(str[i++]);
    }
}

void initspi(void) {
    long junk;

    SPI2CONbits.ON = 0; // disable SPI to reset any previous state
    junk = SPI2BUF; // read SPI buffer to clear the receive buffer
    SPI2CONbits.MODE32 = 1; // 32 bit mode
    SPI2CONbits.MSTEN = 1; // enable master mode
    SPI2CONbits.CKE = 1; // set clock-to-data timing (data centered on rising SCK edge)
    SPI2CONbits.ON = 1; // turn SPI on
}

long spi_send_receive(long send) {
    SPI2BUF = send; // send data to slave
    while (!SPI2STATbits.SPIBUSY); // wait until received buffer fills, indicating data received
    return SPI2BUF; // return received data and clear the read buffer full
}

void read_spi_buf(xcorrdata_t * data) {
    // reads 64 bytes
    data->pair1.l = spi_send_receive(0);
    data->pair2.l = spi_send_receive(0);
}

int main(void) {
    xcorrdata_t data;

    char buffer[BUFSIZE];

    while (1) {
        // read from spi
        read_spi_buf(&data);

        // process data here

        // write over uart
        sprintf("%d,%d\n\r", buffer, data.pair1.data.i, (long int) data.pair1.data.v);
        putstrserial(buffer);
    }
    return 0;
}
