set_parasitic_parameters -early_spec maxTLU -late_spec maxTLU
set_temperature 125
set_process_number 0.99
set_process_label slow
set_voltage 0.95  -object_list VDD
set_voltage 0.00  -object_list VSS

set_operating_conditions ss0p95v125c -library saed32rvt_ss0p95v125c.db

#set_load 5 $mcmm_ports(all_output)
#set_load [expr [load_of saed32lvt_ss0p95v125c/NAND2X1_LVT/A1] * 5 ] $mcmm_ports(scan_out)
source work/slow/accel.sdc
