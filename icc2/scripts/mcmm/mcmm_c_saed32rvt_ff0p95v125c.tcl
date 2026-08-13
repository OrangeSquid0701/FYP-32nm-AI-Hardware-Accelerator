set_parasitic_parameters -early_spec minTLU -late_spec minTLU
set_temperature 125
set_process_number 0.99
set_process_label fast
set_voltage 0.95  -object_list VDD
set_voltage 0.00  -object_list VSS

set_operating_conditions ff0p95v125c -library saed32rvt_ff0p95v125c.db

source work/slow/accel.sdc
