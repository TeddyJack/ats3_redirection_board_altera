`include "defines.v"

module uart_process(
input CLK,
input RST,
input RX,
output TX,

input [15:0] DATA,
input ENA,
input [7:0] MSG_LEN_IN,
input PARITY_IN,
output BUSY,

input RD_REQ,
input MSG_START,
output [15:0] FIFO_Q,
output [7:0] MSG_LEN,
output PARITY_OUT,
output GOT_FULL_MESSAGE
);

uart uart(
.clk(CLK),
.rst(!RST),
// AXI input
.input_axis_tdata(tx_data),		// I make it
.input_axis_tvalid(tx_valid),		// I make it
.input_axis_tready(tx_ready),
// AXI output
.output_axis_tdata(rx_data),
.output_axis_tvalid(rx_valid),
.output_axis_tready(rx_ready),	// I make it
// UART interface
.rxd(RX),
.txd(TX),
// Configuration
.prescale(prescale[15:0])
);
wire [7:0] rx_data;
wire rx_valid;
wire tx_ready;
wire [31:0] prescale = `F_clk/(115200*8);	// = fclk / (baud * 8)

output_process_uart output_process_uart(
.CLK(CLK),
.RST(RST),
.tx_ready(tx_ready),
.tx_data(tx_data),
.tx_valid(tx_valid),
.DATA(DATA),
.ENA(ENA),
.MSG_LEN_IN(MSG_LEN_IN),
.PARITY_IN(PARITY_IN),
.BUSY(BUSY)
);
wire [7:0] tx_data;
wire tx_valid;

input_process_uart input_process_uart(
.CLK(CLK),
.RST(RST),
.rx_ready(rx_ready),
.rx_data(rx_data),
.rx_valid(rx_valid),
.RD_REQ(RD_REQ),
.MSG_START(MSG_START),
.FIFO_Q(FIFO_Q),
.MSG_LEN(MSG_LEN),
.PARITY_OUT(PARITY_OUT),
.GOT_FULL_MESSAGE(GOT_FULL_MESSAGE)
);
wire rx_ready;


endmodule
