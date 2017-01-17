module output_process_spi(
input RST,
input RX_CLK,
output TX_DATA,
output TX_LOAD,
output TX_STOP,

input [15:0] DATA,
input ENA,				// keep in mind that ENA clocked with SYS_CLK, but serializer is driven by RX_CLK, but that's ok, we have 16 safe RX_CLK periods until new ENA gonna be detected
output BUSY
);

serializer serializer(
.CLK(RX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(DATA),
.ENA(ENA),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(BUSY)
);


endmodule
