module redirector(
input CLK_IN,
input RST,
// SPI_0
input RX_CLK0,
input RX_DATA0,
input RX_LOAD0,
input RX_STOP0,
output TX_CLK0,
output TX_DATA0,
output TX_LOAD0,
output TX_STOP0,
// cypress exchange pins
input FLAG_EMPTY,	// FLAGA
input FLAG_FULL,	// FLAGB
inout [15:0] FD,
output SLOE,
output SLWR,
output SLRD,
output [1:0] FIFOADR,
output PKTEND,
output IFCLK,
// LEDs on front panel
output [4:1] LEDS_BA,
output LED_REMOTE,
// UART
input UART0_RX,
output UART0_TX,
input UART1_RX,
output UART1_TX,
// I2C
inout SDA,
inout SCL,
// GPIO
output [3:0] GPIO
);

pll pll(
.inclk0(CLK_IN),
.c0(ifclk)
);
wire ifclk;

assign IFCLK = ifclk;

deserializer deserializer_0(
.RST(RST),
.RX_CLK(RX_CLK0),
.RX_DATA(RX_DATA0),
.RX_LOAD(RX_LOAD0),
.RX_STOP(RX_STOP0),

.P_ADDR(p_addr),
.P_DATA(p_data),
.P_ENA(p_ena)
);
wire [2:0] p_addr;
wire [15:0] p_data;
wire p_ena;

out_fifo out_fifo(
.data(p_data),
.rdclk(ifclk),
.rdreq(fifo_rdrq),
.wrclk(RX_CLK0),
.wrreq(p_ena & (!fifo_full)),
.q(fifo_q),
.rdempty(fifo_empty),
.wrfull(fifo_full)
);
wire fifo_empty;
wire fifo_full;
wire [15:0] fifo_q;

read_write_slave_fifo read_write_slave_fifo(
.CLK(ifclk),
.RST(RST),
.FLAG_EMPTY(FLAG_EMPTY),
.FLAG_FULL(FLAG_FULL),
.FD(FD),
.fifo_empty(fifo_empty),
.fifo_q(fifo_q),

.SLOE(SLOE),
.SLWR(SLWR),
.SLRD(SLRD),
.FIFOADR(FIFOADR),
.PKTEND(PKTEND),
.fifo_rdrq(fifo_rdrq)
);
wire fifo_rdrq;


endmodule
