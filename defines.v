`define NUM_SPI		2	// you must change NUM_SPI value in .sdc file as well
`define NUM_UART		2
`define PREFIX	16'h44BB
`define F_clk	48000000

// calculated based on define
`define NUM_SOURCES	(`NUM_SPI + `NUM_UART)