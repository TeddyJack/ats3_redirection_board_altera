module rising_edge_detect(
input CLOCK,
input RESET,
input LONG_SIGNAL,
output reg RISING_EDGE_PULSE
);

reg previous_long_signal;
always@(posedge CLOCK or negedge RESET)
begin
if(!RESET)
	begin
	RISING_EDGE_PULSE <= 0;
	previous_long_signal <= 1;
	end
else
	begin
	previous_long_signal <= LONG_SIGNAL;
	if((!previous_long_signal) & LONG_SIGNAL)
		RISING_EDGE_PULSE <= 1;
	else
		RISING_EDGE_PULSE <= 0;
	end
end

endmodule
