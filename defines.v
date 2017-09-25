`define NUM_SPI			1			// you must change NUM_SPI value in .sdc file as well
`define NUM_UART			1
`define PREFIX				16'h44BB
`define F_clk				48000000	// Make sure that in PLL the same value
`define PKTEND_PERIOD	5		// in ms
`define GFM_PERIOD		1		// in ms (GFM = got full message), time period of triggering GOT_FULL_MESSAGE if input FIFO is not full enough
`define UART_WORDS		32			// how many words used in FIFO to trigger GOT_FULL_MESSAGE
`define SPI_WORDS			256
`define NUM_LEDS			3
`define BUSY_TIMEOUT		1000		// in ms. In case of busy is too long
`define SPI_3BIT_ADDR	3'd1
`define SPI_FIFO_SIZE	2048		// in words
//`define BIG_ENDIAN



// calculated values based on defines
`define NUM_SOURCES	(`NUM_SPI + `NUM_UART)
`define PKTEND_LIMIT	((`F_clk / 1000) * `PKTEND_PERIOD - 1)
`define GFM_LIMIT		((`F_clk / 1000) * `GFM_PERIOD - 1)
`define BUSY_LIMIT	((`F_clk / 1000) * `BUSY_TIMEOUT - 1)
`define swap_bytes(some_port) {some_port[7:0],some_port[15:8]}