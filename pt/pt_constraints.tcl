set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports "HCLK"]]

create_clock -period 10.0 [get_ports HCLK]
set_propagated_clock [all_clocks]

set_input_delay 0.5 -clock HCLK $all_in_ex_clk

set_output_delay -max 0.5 -clock HCLK [get_ports HRDATA_ACCEL]
set_output_delay -max 0.5 -clock HCLK [get_ports HREADYOUT_ACCEL]
set_output_delay -max 0.5 -clock HCLK [get_ports HRESP_ACCEL]
set_output_delay -max 0.5 -clock HCLK [get_ports HRDATA_FPADD]
set_output_delay -max 0.5 -clock HCLK [get_ports HREADYOUT_FPADD]
set_output_delay -max 0.5 -clock HCLK [get_ports HRESP_FPADD]

set_output_delay -min 0.1 -clock HCLK [get_ports HRDATA_ACCEL]
set_output_delay -min 0.1 -clock HCLK [get_ports HREADYOUT_ACCEL]
set_output_delay -min 0.1 -clock HCLK [get_ports HRESP_ACCEL]
set_output_delay -min 0.1 -clock HCLK [get_ports HRDATA_FPADD]
set_output_delay -min 0.1 -clock HCLK [get_ports HREADYOUT_FPADD]
set_output_delay -min 0.1 -clock HCLK [get_ports HRESP_FPADD]

# These signals are tied to high during RTL 
set_case_analysis 1 [get_ports HREADYOUT_ACCEL]
set_case_analysis 0 [get_ports HRESP_ACCEL]
set_case_analysis 1 [get_ports HREADYOUT_FPADD]
set_case_analysis 0 [get_ports HRESP_FPADD]

set_driving_cell -lib_cell NBUFFX4_RVT -library saed32rvt_ss0p95v125c $all_in_ex_clk
set_load [expr [load_of saed32rvt_ss0p95v125c/NAND2X1_RVT/A1] * 5 ] [all_outputs]

set_operating_conditions "ss0p95v125c"
