module output_process_spi(
input RST,
input TX_CLK,
output TX_DATA,
output TX_LOAD,
input RX_STOP,

input [15:0] DATA,
input ENA,

output [1:0] state_mon
);

assign state_mon = state;

out_fifo_spi out_fifo_spi(
.clock(TX_CLK),
.data(DATA),
.rdreq(rd_req),
.sclr(full | (!RST)),
.wrreq(ENA),
.empty(empty),
.full(full),
.q(fifo_data)
);
wire empty;
wire full;
wire [15:0] fifo_data;
//wire rd_req = !(empty | serializer_busy | RX_STOP);

reg [1:0] state;
parameter wait_for	= 2'h0;
parameter capture		= 2'h1;
parameter skip			= 2'h2;

reg ena;
reg rd_req;

always@(posedge TX_CLK or negedge RST)
begin
if(!RST)
	begin
	state <= wait_for;
	rd_req <= 0;
	ena <= 0;
	end
else
	begin
	ena <= rd_req;
	case(state)
	wait_for:
		begin
		if(!(empty | serializer_busy | RX_STOP))
			begin
			rd_req <= 1;
			state <= capture;
			end
		else
			rd_req <= 0;	// state machine was noticed to stuck in this state with rd_req = 1. This line fights with consequences, not the reason. Should fix in future
		end
	capture:
		begin
		rd_req <= 0;
		state <= skip;
		end
	skip:
		state <= wait_for;
	default:
		begin
		state <= wait_for;
		rd_req <= 0;
		end
	endcase
	end
end

serializer serializer(
.CLK(TX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(fifo_data),
.ENA(ena),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(serializer_busy)
);
wire serializer_busy;


endmodule
