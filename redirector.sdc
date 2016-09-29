create_clock -name "CLK_IN" -period 50MHz [get_ports CLK_IN]
create_clock -name "RX_CLK0" -period 125MHz [get_ports RX_CLK0]
derive_clock_uncertainty
derive_pll_clocks