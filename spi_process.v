module spi_process(
input RST,
input SYS_CLK,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
input RX_STOP,

input RD_REQ,
input RD_REQ_LEN,
output [15:0] FIFO_Q,
output GOT_FULL_MSG,

output [7:0] msg_len_out,

output TX_DATA,
output TX_LOAD,
output TX_STOP,

input [15:0] DATA,
input ENA,
output BUSY
);

input_process_spi input_process_spi(
.RST(RST),
.SYS_CLK(SYS_CLK),
.RX_CLK(RX_CLK),
.RX_DATA(RX_DATA),
.RX_LOAD(RX_LOAD),
.RX_STOP(RX_STOP),

.RD_REQ(RD_REQ),
.RD_REQ_LEN(RD_REQ_LEN),
.FIFO_Q(FIFO_Q),
.GOT_FULL_MSG(GOT_FULL_MSG),
.msg_len_out(msg_len_out)
);

output_process_spi output_process_spi(
.RST(RST),
.RX_CLK(RX_CLK),
.TX_DATA(TX_DATA),
.TX_LOAD(TX_LOAD),
.TX_STOP(TX_STOP),

.DATA(DATA),
.ENA(ENA),
.BUSY(BUSY)
);

endmodule
