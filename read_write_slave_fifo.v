module read_write_slave_fifo(
input CLK,
input RST,
input FLAG_EMPTY,
input FLAG_FULL,
inout [15:0] FD,
input [15:0] fifo_q,
input GOT_FULL_MSG,

output reg SLOE,
output reg SLWR,
output RD_REQ,
output reg SLRD,
output reg [1:0] FIFOADR,
output PKTEND,

output [2:0] state_monitor
);

assign state_monitor = state;
assign FD = SLOE ? 16'hzzzz : data;

reg [15:0] data;
always@(*)
case(data_type)
prefix:	data = 16'hBBBB;
src_len:	data = 16'hCCCC;
payload:	data = fifo_q;
default:	data = 0;
endcase

assign RD_REQ = (data_type == payload) && SLWR;

reg [1:0] data_type;
parameter [1:0] none		= 2'h0;
parameter [1:0] prefix	= 2'h1;
parameter [1:0] src_len	= 2'h2;
parameter [1:0] payload	= 2'h3;

reg [2:0] state;
parameter [2:0] idle						= 3'h0;
parameter [2:0] wr_state1				= 3'h1;
parameter [2:0] wr_state2				= 3'h2;
parameter [2:0] rd_state1				= 3'h3;
parameter [2:0] rd_state2				= 3'h4;
parameter [2:0] rd_state3				= 3'h5;
always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	state <= idle;
	SLWR <= 0;
	FIFOADR <= 0;
	SLOE <= 0;
	SLRD <= 0;
	data_type <= none;
	end
else
	case(state)
	idle:
		begin
		if(!FLAG_EMPTY)		// if Slave FIFO has some data for us
			begin
			FIFOADR <= 2'b00;
			state <= rd_state1;
			end
		else if(!FLAG_FULL && GOT_FULL_MSG)	// if we have some data for Slave FIFO
			begin
			FIFOADR <= 2'b10;
			state <= wr_state1;
			data_type <= prefix;
			end
		end
	wr_state1:	// "0"
		begin
		if(!FLAG_FULL)
			begin
			if((data_type == prefix) || (data_type == src_len) || ((data_type == payload) && GOT_FULL_MSG))
				begin
				state <= wr_state2;
				SLWR <= 1;
				end
			else
				begin
				state <= idle;
				data_type <= none;
				end
			end
		end
	wr_state2:	// "1"
		begin
		SLWR <= 0;
		state <= wr_state1;
		if(data_type == prefix)
			data_type <= src_len;
		else if(data_type == src_len)
			data_type <= payload;
		end
	rd_state1:
		begin
		SLOE <= 1;
		state <= rd_state2;
		end
	rd_state2:
		begin
		if(!FLAG_EMPTY)
			begin
			SLRD <= 1;
			state <= rd_state3;
			end
		else
			begin
			state <= idle;
			SLOE <= 0;
			end
		end
	rd_state3:
		begin
		SLRD <= 0;
		if(!FLAG_EMPTY)
			state <= rd_state2;
		else
			begin
			state <= idle;
			SLOE <= 0;
			end
		end
	endcase
end

endmodule
