#functional mode

# Enable DFT logic and OCC Controller:
# set_case_analysis 0 test_se

# Functional clk
create_clock -period 10 [get_ports HCLK]
