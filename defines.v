`define NUM_SPI		2				// you must change NUM_SPI value in .sdc file as well
`define NUM_UART		2
`define PREFIX			16'h44BB
`define F_clk			48000000		// Make sure that in PLL the same value
`define PKTEND_PERIOD	1000		// in ms


// calculated values based on defines
`define NUM_SOURCES	(`NUM_SPI + `NUM_UART)
`define PKTEND_LIMIT	(`F_clk * (`PKTEND_PERIOD / 1000) - 1)		// Hz * s