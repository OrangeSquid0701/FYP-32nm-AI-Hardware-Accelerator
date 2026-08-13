
read_verilog ../icc2/results/accel_top.v
link_design accelerator_top

read_parasitics -f spef ../icc2/results/accel_top.minTLU_125.spef
#read_parasitics -f spef ../icc2/results/accel_top.maxTLU_125.spef
load_upf ../icc2/results/accel_top.upf

source -echo -verbose pt_constraints.tcl
set power_enable_analysis true
report_analysis_coverage

redirect -file results/pt_clock_ss.rpt {report_clock}
redirect -file results/pt_timing_ss.rpt {report_timing}
redirect -file results/pt_timing_delay_min_ss.rpt {report_timing -delay min}
redirect -file results/pt_power_ss.rpt {report_power}
redirect -file results/pt_qor_ss.rpt {report_qor}redirect -file results/pt_clock.rpt {report_clock}

redirect -file results/pt_clock_ff.rpt {report_clock}
redirect -file results/pt_timing_ff.rpt {report_timing}
redirect -file results/pt_timing_delay_min_ff.rpt {report_timing -delay min}
redirect -file results/pt_power_ff.rpt {report_power}
redirect -file results/pt_qor_ff.rpt {report_qor}


save_session accel_ip_savesession
