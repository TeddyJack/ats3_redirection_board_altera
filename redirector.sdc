set NUM_SPI 4

create_clock -period 48MHz [get_ports CLK_IN]

for {set i 0} {$i < $NUM_SPI} {incr i} {
	create_clock -period 125MHz [get_ports RX_CLK[$i]]
}

derive_pll_clocks

derive_clock_uncertainty

