module read_write_slave_fifo(
input CLK,
input RST,
input FLAG_EMPTY,
input FLAG_FULL,
inout [15:0] FD,
input [15:0] fifo_q,
input GOT_FULL_MSG,
input READ_ALLOW,

output reg SLOE,
output reg SLWR,
output reg SLRD,
output reg [1:0] FIFOADR,
output PKTEND,
output reg fifo_rdrq,

output [2:0] state_monitor
);

assign state_monitor = state;
assign FD = SLOE ? 16'hzzzz : fifo_q;

reg [2:0] state;
parameter [2:0] idle = 0;
parameter [2:0] wr_state1 = 1;
parameter [2:0] wr_state2 = 2;
parameter [2:0] rd_state1 = 3;
parameter [2:0] rd_state2 = 4;
parameter [2:0] rd_state3 = 5;
always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	state <= idle;
	SLWR <= 0;
	fifo_rdrq <= 0;
	FIFOADR <= 0;
	SLOE <= 0;
	SLRD <= 0;
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
		else if(GOT_FULL_MSG)	// if we have some data for Slave FIFO
			begin
			FIFOADR <= 2'b10;
			state <= wr_state1;
			fifo_rdrq <= 1;
			end
		end
	wr_state1:
		begin
		fifo_rdrq <= 0;
		if(!FLAG_FULL)				// if Slave FIFO has free space
			begin
			state <= wr_state2;
			SLWR <= 1;
			end
		end
	wr_state2:
		begin
		SLWR <= 0;
		if(READ_ALLOW)
			begin
			fifo_rdrq <= 1;
			state <= wr_state1;
			end
		else
			begin
			state <= idle;
			end
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
