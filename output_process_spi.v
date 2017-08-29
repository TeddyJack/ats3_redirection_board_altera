module output_process_spi(
input RST,
input TX_CLK,
output TX_DATA,
output TX_LOAD,
input RX_STOP,

input [15:0] DATA,
input ENA,
output BUSY
);

assign BUSY = serializer_busy | RX_STOP;

serializer serializer(
.CLK(TX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(DATA),
.ENA(ENA),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(serializer_busy)
);
wire serializer_busy;


endmodule
