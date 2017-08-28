`define NUM_SPI			4			// you must change NUM_SPI value in .sdc file as well
`define NUM_UART			2
`define PREFIX				16'h44BB
`define F_clk				48000000	// Make sure that in PLL the same value
`define PKTEND_PERIOD	1000		// in ms
`define GFM_PERIOD		500		// in ms (GFM = got full message), time period of triggering GOT_FULL_MESSAGE if input FIFO is not full enough
`define UART_WORDS		32			// how many words used in FIFO to trigger GOT_FULL_MESSAGE
`define SPI_WORDS			256
`define NUM_LEDS			3
`define BIG_ENDIAN					// FIX IT! uncomment this line for easy debug. Right order of bytes inside word



// calculated values based on defines
`define NUM_SOURCES	(`NUM_SPI + `NUM_UART)
`define PKTEND_LIMIT	((`F_clk / 1000) * `PKTEND_PERIOD - 1)
`define GFM_LIMIT		((`F_clk / 1000) * `GFM_PERIOD - 1)
`ifdef BIG_ENDIAN
	`define FD_CONNECT	{FD[7:0],FD[15:8]}
`else
	`define FD_CONNECT	FD					// doesn't work yet
`endif