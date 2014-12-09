#include "p32xxxx.h"
#include <stdio.h>

#define BUFSIZE 30
#define NUM_PAIRS 2

typedef struct {
    unsigned char i;
    signed long int v:24;
} pairdata_t;

typedef struct {
    pairdata_t pair[2];
} xcorrdata_t;

void initUART(void)
{
    // Configure UART
    // Using UART2

    //TRISB = 0x0000;

    TRISFbits.TRISF4 = 0; // TX (output)

    // Want rate of 115.2 Kbaud
    // Assuming PIC peripheral clock Fpb = Fosc / 2 = 20 MHz
    // based on default instructions in lab 1.
    // U6BRG = (Fpb / 4*baud rate) - 1
    // -> U6BRG = 10 (decimal)
    // Actual baud rate 113636.4 (-1.2% error)
    U2BRG = 21;

    // UART2 Mode Register
    // bit 31-16: unused
    // bit 15:  ON = 1: enable UART
    // bit 14:  FRZ = 0: don't care when CPU in normal state
    // bit 13:  SIDL = 0: don't care when CPU in normal state
    // bit 12:  IREN = 0: disable IrDA
    // bit 11:  RTSMD = 0: don't care if not using flow control
    // bit 10:  unused
    // bit 9-8: UEN = 00: enable U1TX and U1RX, disable U1CTSb and U1RTSb
    // bit 7:   WAKE = 0: do not wake on UART if in sleep mode
    // bit 6:   LPBACK = 0: disable loopback mode
    // bit 5:   ABAUD = 0: don't auto detect baud rate
    // bit 4:   RXINV = 0: U1RX idle state is high
    // bit 3:   BRGH = 0: standard speed mode
    // bit 2-1: PDSEL = 00: 8-bit data, no parity
    // bit 0:   STSEL = 0: 1 stop bit
    U2MODE = 0x8000;

    // UART2 Status and control register
    // bit 31-25: unused
    // bit 13: UTXINV = 0: U1TX idle state is high
    // bit 12: URXEN = 0: enable receiver
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
    U2STA = 0x0400;
}

void putcharserial(char c)
{
    while (U2STAbits.UTXBF); // wait until transmit buffer empty
    U2TXREG = c; // transmit character over serial port
}

void putstrserial(char *str)
{
    int i = 0;
    while (str[i] != 0) {
        putcharserial(str[i++]);
    }
}

void initspi(void) {
//    // send a reset signal to the FPGA to ensure clocks are aligned
//    PORTDbits.RD0 = 1;
//    int j;
//    for (j=0;j<100;j++)
//        j++;
//    PORTDbits.RD0 = 0;

    long junk;

    SPI2CONbits.ON = 0; // disable SPI to reset any previous state
    junk = SPI2BUF; // read SPI buffer to clear the receive buffer
    SPI2BRG = 7; //set BAUD rate to 1.25MHz, with Pclk at 20MHz
    SPI2CONbits.MODE32 = 1; // 32 bit mode
    SPI2CONbits.MSTEN = 1; // enable master mode
    SPI2CONbits.CKE = 1; // set clock-to-data timing (data centered on rising SCK edge)
    SPI2CONbits.ON = 1; // turn SPI on
}

long spi_send_receive(long send) {
    SPI2BUF = send; // send data to slave
    while (!SPI2STATbits.SPIBUSY); // wait until received buffer fills, indicating data received
    while (!SPI2STATbits.SPITBE);
    return SPI2BUF; // return received data and clear the read buffer full
}

void read_spi_buf(xcorrdata_t * data) {
    // reads 64 bytes
    long bits;

    struct {
      signed long v:24;
    } s;

    unsigned int p;
    for (p = 0; p < NUM_PAIRS; p++) {
        bits = spi_send_receive(0);
        s.v = bits & 0x00FFFFFF;
        data->pair[p].v = (signed long) s.v;
        data->pair[p].i = (unsigned char) (bits >> 24);
    }
}

int main(void) {
    initspi();
    initUART();
    xcorrdata_t data;

    TRISD = 0xFF00;
    PORTD = 0x0;

    char buffer[BUFSIZE];
    int i;

    double angle = 0;
    long int maximum = 200000;

    unsigned char index;
    long int max;
    int curr_angle;

    double conf;
    double lastconf = 0;
    double alpha = 0.25; // average coeff

    while (1) {
        // read from spi
        read_spi_buf(&data);

        // process data here
        index = data.pair[0].i;
        max = data.pair[0].v;
        
//        maximum -= 2; //
//
//        if (max > maximum)
//            maximum = max;
        
        // (kalman filter esque)
        // conf -=  0.7
        // conf = 1 - (1-conf)*(1-curr_conf)
        // combine conf with new conf to make it higher (perhaps not as high as it once was)
        // conf tends to decrease without measurements
        
        // conf can only increase when we combine with new conf
        
       
        curr_angle = (((int) index) - 129) << 1;
        
        // use max as confidence estimate
        conf = (max > maximum) ? 1.0 : ((double) max)/maximum;

        //lowpass the conf
        conf = (1-alpha)*lastconf + alpha*conf;

        angle = conf*curr_angle + (1.0-conf)*angle;

        //ensure angle stays between bounds
        if (angle > 120)
            angle = 120;
        if (angle < -120)
            angle = -120;

        // write over uart
        //memset(buffer, 0, BUFSIZE);
        i = sprintf(buffer, "%03f,%03f,%d,%d\n\r\0",  angle, conf, max, curr_angle);
        if( i > 0 )
            putstrserial(buffer);


        for (i=0; i<1000; i++); // delay pls

    }
    return 0;
}
