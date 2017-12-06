module output_process_spi(
input RST,
input TX_CLK,
output TX_DATA,
output TX_LOAD,
input RX_STOP,

input [15:0] DATA,
input ENA
);

out_fifo_spi out_fifo_spi(
.clock(TX_CLK),
.data(DATA),
.rdreq(rd_req),
.sclr(full),
.wrreq(ENA),
.empty(empty),
.full(full),
.q(fifo_data)
);
wire empty;
wire full;
wire [15:0] fifo_data;
wire rd_req = !(empty | serializer_busy | RX_STOP);

serializer serializer(
.CLK(TX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(fifo_data),
.ENA(rd_req),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(serializer_busy)
);
wire serializer_busy;


endmodule
