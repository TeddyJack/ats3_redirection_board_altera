`include "defines.v"

module read_write_slave_fifo(
input CLK,
input RST,
input FLAG_EMPTY,
input FLAG_FULL,
inout [15:0] FD,
input [(`NUM_SOURCES*16-1):0] fifo_q_bus, 
input [(`NUM_SOURCES-1):0] GOT_FULL_MSG,
input [(`NUM_SOURCES-1):0] SERIALIZER_BUSY,
input [(`NUM_SOURCES*8-1):0] MSG_LEN_BUS,

output reg SLOE,
output reg SLWR,
output [(`NUM_SOURCES-1):0] RD_REQ,
output reg [(`NUM_SOURCES-1):0] MSG_START,
output reg SLRD,
output reg [1:0] FIFOADR,
output reg PKTEND,
output [(`NUM_SOURCES-1):0] ENA,

input [(`NUM_SOURCES-1):0] PARITY_IN,
output reg PARITY_OUT,
output reg [7:0] payload_len,

output [2:0] state_monitor,
output reg [7:0] payload_counter,
output [1:0] data_type_mon
);

assign state_monitor = state;
assign data_type_mon = data_type;
assign FD = SLOE ? 16'hzzzz : data;

wire [15:0] fifo_q [(`NUM_SOURCES-1):0];
wire [7:0] MSG_LEN [(`NUM_SOURCES-1):0];
wire [(`NUM_SOURCES-1):0] single_one = 1;
wire [(`NUM_SOURCES-1):0] decoder_out = (single_one << current_source);
genvar i;
generate
for(i=0; i<`NUM_SOURCES; i=i+1)
	begin: wow
	assign fifo_q[i] = fifo_q_bus[(16*i+15):(16*i)];
	assign MSG_LEN[i] = MSG_LEN_BUS[(8*i+7):(8*i)];
	// demultiplexing ENA and RD_REQ
	assign ENA[i] = decoder_out[i] && (SLRD && (data_type == payload));		// simpliest demultiplexer = decoder + 4 ands. decoder implemented with leftshift
	assign RD_REQ[i] = decoder_out[i] && ((data_type == payload) && SLWR);
	end
endgenerate



reg [15:0] data;
always@(*)
case(data_type)
prefix:	data = `PREFIX;
src_len:	begin
			data[15:13]	= 0;
			data[12]		= PARITY_IN[current_source];
			data[11:8]	= current_source;
			data[7:0]	= MSG_LEN[current_source];
			end
payload:	data = fifo_q[current_source];
default:	data = 0;
endcase

reg [1:0] data_type;
parameter [1:0] none		= 2'h0;
parameter [1:0] prefix	= 2'h1;
parameter [1:0] src_len	= 2'h2;
parameter [1:0] payload	= 2'h3;

//reg [($clog2(`NUM_SOURCES)-1):0] current_source;		// that's very good expression to calculate bus width from NUM_SOURCES, but it leads to "truncated" warning
reg [3:0] current_source;										// so I've written maximum bus width
//reg [(`NUM_SOURCES-1):0] MSG_SENT;						// not used signal. may be valuable in future

reg [2:0] state;
parameter [2:0] idle						= 3'h0;
parameter [2:0] wr_state1				= 3'h1;
parameter [2:0] wr_state2				= 3'h2;
parameter [2:0] rd_state1				= 3'h3;
parameter [2:0] rd_state2				= 3'h4;
parameter [2:0] rd_state3				= 3'h5;
parameter [2:0] timeout					= 3'h6;
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
	payload_counter <= 0;
	payload_len <= 0;
	current_source <= 0;
	PARITY_OUT <= 0;
	//MSG_SENT <= 0;
	MSG_START <= 0;
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
		else if(!FLAG_FULL)	// if we have some data for Slave FIFO
			begin
			if(GOT_FULL_MSG[current_source])
				begin
				FIFOADR <= 2'b10;
				state <= wr_state1;
				data_type <= prefix;
				end
			else
				begin
				if(current_source < `NUM_SOURCES)
					current_source <= current_source + 1'b1;
				else
					current_source <= 0;
				end
			end
		end
	wr_state1:	// "0"
		begin
		if(!FLAG_FULL)
			begin
			if((data_type == prefix) || (data_type == src_len) || ((data_type == payload) && (payload_counter < MSG_LEN[current_source])))
				begin
				state <= wr_state2;
				SLWR <= 1;
				if(data_type == payload)
					payload_counter <= payload_counter + 1'b1;
				if(data_type == prefix)
					MSG_START[current_source] <= 1;
				end
			else
				begin
				state <= timeout;
				data_type <= none;
				payload_counter <= 0;
				//MSG_SENT[current_source] <= 1;
				end
			end
		end
	wr_state2:	// "1"
		begin
		MSG_START[current_source] <= 0;
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
		data_type <= prefix;
		end
	rd_state2:
		begin
		if(!FLAG_EMPTY)
			begin
			if(!SERIALIZER_BUSY[current_source])
				begin
				SLRD <= 1;
				state <= rd_state3;
				end
			end
		else
			begin
			state <= idle;
			SLOE <= 0;
			data_type <= none;
			end
		end
	rd_state3:
		begin
		SLRD <= 0;
		state <= rd_state2;
		if((data_type == prefix) && (FD == `PREFIX))
			begin
			data_type <= src_len;
			end
		else if(data_type == src_len)
			begin
			data_type <= payload;
			PARITY_OUT <= FD[12];
			current_source <= FD[11:8];	// size of current_source
			payload_len <= FD[7:0];
			end
		else if(data_type == payload)
			begin
			if(payload_counter < (payload_len - 1'b1))
				payload_counter <= payload_counter + 1'b1;
			else
				begin
				payload_counter <= 0;
				data_type <= prefix;
				end
			end
		end
	timeout:
		begin
		//MSG_SENT[current_source] <= 0;
		if(payload_counter < 2)	// таймаут 2 такта
				payload_counter <= payload_counter + 1'b1;
			else
				begin
				state <= idle;
				payload_counter <= 0;
				end
		end
	endcase
end

// PKTEND machine
reg [7:0] words_in_page;
reg [31:0] time_counter;
always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	words_in_page <= 0;
	time_counter <= 0;
	PKTEND <= 0;
	end
else
	begin
	if((SLWR && (words_in_page == 8'd255)) || ((time_counter == `PKTEND_LIMIT) && (state == idle)))
		time_counter <= 0;
	else if(time_counter < `PKTEND_LIMIT)
		time_counter <= time_counter + 1'b1;
	
	if((time_counter == `PKTEND_LIMIT) && (state == idle))
		begin
		if(words_in_page)
			PKTEND <= 1;
		words_in_page <= 0;
		end
	else
		begin
		PKTEND <= 0;
		if(SLWR)
			words_in_page <= words_in_page + 1'b1;
		end
	end
end


endmodule
