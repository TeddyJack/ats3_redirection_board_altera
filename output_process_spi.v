module output_process_spi(
input RST,
input RX_CLK,
output TX_DATA,
output TX_LOAD,
output TX_STOP,

input [15:0] FD,		// not sure input or inout
input SLRD,				// keep in mind that SLRD clocked with SYS_CLK, but serializer is driven by RX_CLK, but that's ok, we have 16 safe RX_CLK periods until new SLRD gonna be detected
output BUSY
);

wire [15:0] DF = {FD[7:0],FD[15:8]};	// words are transferred via cypress in little-endian format, we convert into big-endian

serializer serializer(
.CLK(RX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(DF),
.ENA(SLRD),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(BUSY)
);


endmodule
