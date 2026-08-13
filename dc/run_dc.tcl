#read RTL design and link
read_verilog {../rtl/accelerator_top.v ../rtl/systolic_with_ahb.v ../rtl/tile_add_ahb.v ../rtl/input_skew_buffer.v ../rtl/output_deskew_buffer.v ../rtl/ahb_wrapper.v ../rtl/systolic_4x4_ws.v ../rtl/pe_ws.v ../rtl/fp_add.v ../rtl/fp_mul.v }
current_design accelerator_top
link

#implement constraints
source -echo accel_ip.con

#optimize the register
#set_optimize_registers true -design SIPO
#set_optimize_registers true -design PISO
#set_optimize_registers true -design MULT

#fix DRC violation
#set_cost_priority -delay

#dynamic power optimization
set_dynamic_optimization true

#leakage power optimization
set_leakage_optimization true

# Multi-Vt GROUP
#set_user_attribute [get_libs saed14lvt_ss0p72v125c] default_threshold_voltage_group LVT
#set_user_attribute [get_libs saed14rvt_ss0p72v125c] default_threshold_voltage_group RVT
#set_user_attribute [get_libs saed14hvt_ss0p72v125c] default_threshold_voltage_group HVT

compile_ultra

report_timing -path full -delay max -max_paths 1 > results/setup.rpt
report_timing -path full -delay min -max_paths 1 > results/hold.rpt
report_qor > results/report_qor.rpt
report_area > results/report_area.rpt
report_constraints -all > results/constraints.rpt
report_threshold_voltage_group > results/vth_grp.rpt

#report_qor
#report_constraint -all
#report_power

write_sdc ../icc2/work/slow/accel.sdc
write_file -f ddc -hier -output ../netlist/accel_ip.ddc
write -f verilog -hier -output ../netlist/accel_ip.v

#foreach period {10.0 7.0 5.0 3.0 2.0 1.0 0.8 0.5} {
#    # 1. Update the Clock
#    create_clock -period $period [get_ports HCLK]

    # 2. Re-optimize the design
#    compile_ultra -incremental

    # 3. Save unique reports for each frequency
#    set freq [expr 1000 / $period]
##    redirect -file char/report_p${period}_power.txt { report_power }
#    redirect -file char/report_p${period}_area.txt { report_area }
#    redirect -file char/report_p${period}_setup_timing.txt { report_timing }
#    redirect -file char/report_p${period}_hold_timing.txt { report_timing -delay min }
#    redirect -file char/report_p${period}_vt.txt { report_threshold_voltage_group }
#}

exit
