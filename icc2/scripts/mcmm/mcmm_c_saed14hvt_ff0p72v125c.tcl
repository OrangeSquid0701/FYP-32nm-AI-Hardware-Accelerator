set_parasitic_parameters -early_spec minTLU -late_spec minTLU
set_temperature 125
set_process_number 0.99
set_process_label fast
set_voltage 0.72  -object_list VDD
set_voltage 0.00  -object_list VSS

set_operating_conditions ff0p72v125c -library saed14hvt_ff0p72v125c

source work/slow/accel.sdc
