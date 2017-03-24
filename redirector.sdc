set NUM_SPI 2

create_clock -period 50MHz [get_ports CLK_IN]

for {set i 0} {$i < $NUM_SPI} {incr i} {
	create_clock -period 125MHz [get_ports RX_CLK[$i]]
}

derive_clock_uncertainty

derive_pll_clocks