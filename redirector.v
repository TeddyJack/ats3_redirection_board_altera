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

assign TX_CLK0 = RX_CLK0;

pll pll(
.inclk0(CLK_IN),
.c0(ifclk)
);
wire ifclk;

assign IFCLK = ifclk;

input_process_spi input_process_spi(
.RST(RST),
.SYS_CLK(ifclk),
.RX_CLK(RX_CLK0),
.RX_DATA(RX_DATA0),
.RX_LOAD(RX_LOAD0),
.RX_STOP(RX_STOP0),

.RD_REQ(rd_req),
.FIFO_Q(fifo_q),
.GOT_FULL_MSG(got_full_msg),

.type_ver_now(type_ver_now)
);
wire [15:0] fifo_q;
wire got_full_msg;
wire type_ver_now;

output_process_spi output_process_spi(
.RST(RST),
.RX_CLK(RX_CLK0),
.TX_DATA(TX_DATA0),
.TX_LOAD(TX_LOAD0),
.TX_STOP(TX_STOP0),
.type_ver_now(type_ver_now)
);

read_write_slave_fifo read_write_slave_fifo(
.CLK(ifclk),
.RST(RST),
.FLAG_EMPTY(FLAG_EMPTY),
.FLAG_FULL(FLAG_FULL),
.FD(FD),
.fifo_q(fifo_q),
.GOT_FULL_MSG(got_full_msg),

.SLOE(SLOE),
.SLWR(SLWR),
.RD_REQ(rd_req),
.SLRD(SLRD),
.FIFOADR(FIFOADR),
.PKTEND(PKTEND)
);
wire rd_req;

endmodule
