### Pre-placement stage ###
report_qor -summary

report_ideal_network -scenarios [all_scenarios]
report_ignored_layers
report_host_options
report_design -summary
get_scan_chain_count
check_scan_chain
report_utilization
check_design -checks pre_placement_stage
check_design -checks physical_constraints
report_net_fanout -high_fanout

#cts_setup

report_app_options place.coarse.auto_density_control
set_app_options -name place.coarse.enhanced_auto_density_control -value true

#reset_app_options opt.dft.optimize_scan_chain
#report_app_options  opt.dft.optimize_scan_chain

set_app_options -name place.legalize.enable_advanced_legalizer -value true

### placement stage ###
place_opt
#from running each placement stage, utilization decreases

### Post-placement stage###
# legalize_placement -incr
# check_legality

# report_congestion
# report_utilization
# report_mv_design
report_timing
# report_timing -report_by scenario
# report_timing -report_by group
