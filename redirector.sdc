create_clock -name "CLK_IN" -period 50MHz [get_ports CLK_IN]
create_clock -name "RX_CLK[0]" -period 125MHz [get_ports RX_CLK[0]]
create_clock -name "RX_CLK[1]" -period 125MHz [get_ports RX_CLK[1]]
create_clock -name "RX_CLK[2]" -period 125MHz [get_ports RX_CLK[2]]
create_clock -name "RX_CLK[3]" -period 125MHz [get_ports RX_CLK[3]]
derive_clock_uncertainty
derive_pll_clocks