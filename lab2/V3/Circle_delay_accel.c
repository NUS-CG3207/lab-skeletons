#define IROM_BASE 0x00000000		// make sure this is the same as the .txt address based on the Memory Configuration set in the assembler/linker 
                                        // and the PC default value as well as reset value in **ProgramCounter.v** 
#define DMEM_BASE 0x00002000   	// make sure this is the same as the .data address based on the Memory Configuration set in the assembler/linker
#define DMEM_SIZE 0x400        // 2**DMEM_DEPTH_BITS
#define MMIO_BASE DMEM_BASE + DMEM_SIZE   // assuming MMIO is also in the .data segment
#define STACK_INIT MMIO_BASE // make it the same as HDL, top of RAM to allow stack to grow downwards

// Memory-mapped peripheral register offsets
#define LED_OFF 0x00 //WO
#define DIP_OFF 0x04  //RO
#define PB_OFF  0x08 //RO
#define UART_OFF 0x0C //RW
#define UART_RX_VALID_OFF 0x10 //RO, status bit
#define UART_RX_READY_OFF 0x14 //RO, status bit
#define SEVENSEG_OFF 0x18 //WO
#define CYCLECOUNT_OFF 0x1C //WO
#define OLED_COL_OFF 0x20 //WO
#define OLED_ROW_OFF 0x24 //WO
#define OLED_DATA_OFF 0x28 //WO
#define OLED_CTRL_OFF 0x2C //WO
#define ACCEL_DATA_OFF 0x30 //RO
#define ACCEL_DREADY_OFF 0x34 //RO, status bit. 
                // Not using ACCEL_DREADY_OFF as we poll at a low freq, should be ready

void drawFilledMidpointCircleSinglePixelVisit(int centerX, int centerY, int radius, unsigned int colour);
void drawHorizontalLine(int startX, int endX, int Y, unsigned int colour);
void delay(unsigned int cycles);
volatile unsigned int* CYCLECOUNT_ADDR = (unsigned int*) (MMIO_BASE+CYCLECOUNT_OFF); 
// making CYCLECOUNT_ADDR global just to use data memory :)

int main()
{
    asm volatile("li sp, %0" : : "i" (STACK_INIT)); //inline assembly to init sp. Registers cant be accessed explicitly in pure C
    volatile unsigned int* ACCEL_Data_ADDR = (unsigned int*) (MMIO_BASE+ACCEL_DATA_OFF); // temp, x, y, z
    volatile unsigned int* UART_TX_ready_ADDR = (unsigned int*) (MMIO_BASE+UART_RX_READY_OFF);
    volatile unsigned int* UART_ADDR = (unsigned int*) (MMIO_BASE+UART_OFF); // temp, x, y, z
    volatile unsigned int* SEVENSEG_ADDR = (unsigned int*) (MMIO_BASE+SEVENSEG_OFF);

    while(1)
    {
        unsigned int accel_reading = *ACCEL_Data_ADDR;
        unsigned int accel_reading_mag = 0;
        int accel_reading_mag_byte = 0;

        // display the magnitude on seven segment display
        *SEVENSEG_ADDR = accel_reading;

        // print the raw binary value and magnitude directly. 
        // Configure serial terminal app to display as hex.
        for(int i=24; i>=0; i-=8) 
        {
            // print the raw binary value
            while(!(*UART_TX_ready_ADDR)); // wait for UART to be ready
            // no need to mask it as UART ignores all excel LSByte
            *UART_ADDR = accel_reading >> i;

            accel_reading_mag_byte = ( accel_reading << (24-i) ) & 0xFF000000;
            if(accel_reading_mag_byte<0)    // find magnitude
            {
                accel_reading_mag_byte = -accel_reading_mag_byte;
            }
            // accel_reading_mag_byte is +ve at this point. Right shift logical = arith
            accel_reading_mag += ( accel_reading_mag_byte >> (24-i) );

            // print the magnitude
            while(!(*UART_TX_ready_ADDR));
            *UART_ADDR = accel_reading_mag_byte >> 24;
        }
        // Sending to UART and abs() is easier if there is byte addressability

        // using accel value directly. 2g+-2g range, so multiply mag by 2 (<<1) to have full brightness at 1g
        drawFilledMidpointCircleSinglePixelVisit(48, 32, 28, accel_reading_mag << 1); 
        
        // 1000000 for ~1/3 sec at CLK_DIV_BITS = 5.
        delay(1000000); // change to a much smaller value for simulation
    }
    return 0;
}

void drawFilledMidpointCircleSinglePixelVisit(int centerX, int centerY, int radius, unsigned int colour)
{
// Function Courtesy: https://stackoverflow.com/a/24527943
    int x = radius;
    int y = 0;
    int radiusError = 1 - x;

    while (x >= y)  // iterate to the circle diagonal
    {
        // use symmetry to draw the two horizontal lines at this Y with a special case to draw
        // only one line at the centerY where y == 0
        int startX = -x + centerX;
        int endX = x + centerX;
        drawHorizontalLine( startX, endX, y + centerY, colour );
        if (y != 0)
        {
            drawHorizontalLine( startX, endX, -y + centerY, colour );
        }

        // move Y one line
        y++;

        // calculate or maintain new x
        if (radiusError<0)
        {
            radiusError += 2 * y + 1;
        }
        else 
        {
            // we're about to move x over one, this means we completed a column of X values, use
            // symmetry to draw those complete columns as horizontal lines at the top and bottom of the circle
            // beyond the diagonal of the main loop
            if (x >= y)
            {
                startX = -y + 1 + centerX;
                endX = y - 1 + centerX;
                drawHorizontalLine( startX, endX,  x + centerY, colour);
                drawHorizontalLine( startX, endX, -x + centerY, colour );
            }
            x--;
            radiusError += 2 * (y - x + 1);
        }
    }
}

void drawHorizontalLine(int startX, int endX, int Y, unsigned int colour)
{
    volatile unsigned int* OLED_ROW_ADDR = (unsigned int*) (MMIO_BASE + OLED_ROW_OFF);
    volatile unsigned int* OLED_COL_ADDR = (unsigned int*) (MMIO_BASE + OLED_COL_OFF);
    volatile unsigned int* OLED_DATA_ADDR = (unsigned int*) (MMIO_BASE + OLED_DATA_OFF);
    volatile unsigned int* OLED_CTRL_ADDR = (unsigned int*) (MMIO_BASE + OLED_CTRL_OFF);

    *OLED_ROW_ADDR = Y; // Y
    // 24-bit mode (allows acc data directly), varying x (COL)
    *OLED_CTRL_ADDR = 0x21;
    *OLED_DATA_ADDR = colour;
    for(int i=startX; i<=endX; i++)
    {
        *OLED_COL_ADDR = i;
    }
}

void delay(unsigned int cycles)
{
    unsigned int starting_count = *CYCLECOUNT_ADDR;
    while(*CYCLECOUNT_ADDR < starting_count + cycles);
}


// Caution: Cycle counter rolls over at 42 seconds at 100 MHz. 
    // Change counter width and bits used in Wrapper.v for a longer duration, but lower cycles precision

// OLED_CTRL[3:0] - 0x0: vary_pix_data_mode; 0x1: vary_COL_mode (x); 0x2: vary_ROW_mode (y)
    // Change that triggers a write. We can vary one of them (e.g., column) while keeping the 
    // other two the same, which can be efficient like in this example program.
// OLED_CTRL[7:4] - 0x0: 7-bit colour mode; 0x1: 16-bit colour mode; 0x2: 24-bit colour mode
// 7-bit colour mode: 1 byte per pixel, memory efficient especially if loading bitmapped images
// 16-bit colour mode: Highest colour depth supported by the OLED in a compact representation. OLED input format
// 24-bit colour mode: Similar to standard displays, but some LSBs are not used. Easy to debug. Wrapper output format
// If you want only a specific axis or temperature, use a combination of logical operators and shift
    // e.g., extract Y using (*ACC_DATA_ADDR & 0x0000FF00) >> 8

// Where possible, it is a good idea to test your algorithms in a standard C compiler 
    // e.g., masking and shifts to deal with bytes within a word.

// In order to print a properly formatted text, the characters sent to UART should be printable (ASCII)