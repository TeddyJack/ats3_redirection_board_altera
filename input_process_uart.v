module input_process_uart(
input CLK,
input RST,
output rx_ready,
input [7:0] rx_data,
input rx_valid,

input RD_REQ,
input RD_REQ_LEN,
output [15:0] FIFO_Q,
output [7:0] MSG_LEN,
output PARITY_OUT,
output GOT_FULL_MESSAGE
);





endmodule
