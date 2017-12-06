module spi_process(
input RST,
input SYS_CLK,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
input RX_STOP,

input RD_REQ,
input MSG_START,
output [15:0] FIFO_Q,
output GOT_FULL_MSG,

output [7:0] MSG_LEN,

output TX_DATA,
output TX_LOAD,
output TX_STOP,

input [15:0] DATA,
input ENA
);

input_process_spi input_process_spi(
.RST(RST),
.SYS_CLK(SYS_CLK),
.RX_CLK(RX_CLK),
.RX_DATA(RX_DATA),
.RX_LOAD(RX_LOAD),
.TX_STOP(TX_STOP),

.RD_REQ(RD_REQ),
.MSG_START(MSG_START),
.FIFO_Q(`ifdef BIG_ENDIAN FIFO_Q `else `swap_bytes(FIFO_Q) `endif),
.GOT_FULL_MSG(GOT_FULL_MSG),
.MSG_LEN(MSG_LEN)
);

output_process_spi output_process_spi(
.RST(RST),
.TX_CLK(SYS_CLK),
.TX_DATA(TX_DATA),
.TX_LOAD(TX_LOAD),
.RX_STOP(RX_STOP),

.DATA(DATA),
.ENA(ENA)
);

endmodule
