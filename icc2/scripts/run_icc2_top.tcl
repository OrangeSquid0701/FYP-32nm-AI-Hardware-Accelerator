####################################################################
#                                                                  #
#                           DESIGN SETUP                           #
#                                                                  #
####################################################################

set NDM_PATH "/data/synopsys/lib/saed32nm/lib"

set REF_LIBS " \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_c.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_pg_c.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_dlvl_v.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_ulvl_v.ndm
"

create_lib ACCEL2_LIB \
  -technology /data/synopsys/lib/saed32nm/lib/tech/milkyway/saed32nm_1p9m_mw.tf \
  -ref_libs $REF_LIBS

derive_design_level_via_regions

report_ref_lib
open_lib ACCEL2_LIB

# Read RC parasitic (min & max)
read_parasitic_tech \
        -layermap /data/synopsys/lib/saed32nm/lib/tech/star_rc/saed32nm_tf_itf_tluplus.map \
        -tlup /data/synopsys/lib/saed32nm/lib/tech/star_rc/saed32nm_1p9m_Cmax.tluplus \
        -name maxTLU
read_parasitic_tech \
        -layermap /data/synopsys/lib/saed32nm/lib/tech/star_rc/saed32nm_tf_itf_tluplus.map \
        -tlup /data/synopsys/lib/saed32nm/lib/tech/star_rc/saed32nm_1p9m_Cmin.tluplus \
        -name minTLU

#read_parasitic_tech \
        -layermap /data/synopsys/lib/saed14nm/lib/tech/star_rc/saed14nm_tf_itf_tluplus.map \
        -tlup /data/synopsys/lib/saed14nm/lib/tech/star_rc/min/saed14nm_1p9m_Cmin.tluplus \
        -name minTLU
#read_parasitic_tech \
        -layermap /data/synopsys/lib/saed14nm/lib/tech/star_rc/saed14nm_tf_itf_tluplus.map \
        -tlup /data/synopsys/lib/saed14nm/lib/tech/star_rc/max/saed14nm_1p9m_Cmax.tluplus \
        -name maxTLU

get_parasitic_techs {minTLU maxTLU}
report_lib -parasitic_tech [current_lib]

#read gate level netlist
read_verilog -top accelerator_top ../netlist/accel_ip.v
# read_sdc work/slow/accel.sdc (Used after creating MCMM)
link_block

# Defining metal layer direction
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction vertical
get_attribute [get_layers M?] routing_direction

#default site
set_attribute [get_site_defs unit] is_default true

# Scan chain
# read_def work/MYTOP.scandef

# Connect PG pins to supply nets
connect_pg_net
# check_mv_design

####################################################################
#                                                                  #
#                          FLOORPLANNING                           #
#                                                                  #
####################################################################

initialize_floorplan -core_utilization 0.6 -side_ratio {1 1} -core_offset {20}

shape_blocks
connect_pg_net

set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
create_placement -floorplan

# Place all input ports
place_pins -ports [all_inputs]

# Place all output ports
place_pins -ports [all_outputs]

#set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6} -pin_spacing 10
#place_pins -self

if ![sizeof_collection [get_nets VDD]] {create_net -power VDD}
if ![sizeof_collection [get_nets VSS]] {create_net -ground VSS}

connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]

####################################################################
#                                                                  #
#                      POWER NETWORK SYNTHESIS                     #
#                                                                  #
####################################################################

remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect > /dev/null

#power ring
create_pg_ring_pattern ring_pattern -horizontal_layer M5 -horizontal_width {4} -horizontal_spacing {3} -vertical_layer M6 -vertical_width {4} -vertical_spacing {3}

set_pg_strategy core_ring -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {3 3}}} -core

compile_pg -strategies core_ring

#PG mesh pattern
create_pg_mesh_pattern mesh_pattern7 \
-layers {{{horizontal_layer: M7} {width: 4} {pitch: 35} {offset: 20}}}

create_pg_mesh_pattern mesh_pattern8 \
-layers {{{vertical_layer: M8} {width: 4} {pitch: 35} {offset: 20}}}

create_pg_mesh_pattern mesh_pattern_bottom \
-layers {{{vertical_layer: M2} {width: 1.5} {pitch: 35} {offset: 20}}}
# 50 35
set_pg_strategy M8_mesh \
   -pattern {{name: mesh_pattern8} {nets: VDD VSS}} \
   -design_boundary
set_pg_strategy M7_mesh \
   -pattern {{name: mesh_pattern7} {nets: VDD VSS}} \
   -design_boundary

set_pg_strategy M2_mesh \
   -pattern {{name: mesh_pattern_bottom} {nets: VDD VSS}} \
   -design_boundary

compile_pg -strategies M8_mesh
compile_pg -strategies M7_mesh
compile_pg -strategies M2_mesh

#PG rail
create_pg_std_cell_conn_pattern rail_pattern -layers M1

set_pg_strategy M1_rails \
   -core \
   -pattern {{name: rail_pattern}{nets: VDD VSS}}

compile_pg -strategies M1_rails

#via
set_pg_via_master_rule VIA_2x1 -via_array_dimension {2 1}
set_pg_strategy_via_rule via_stdcell_mesh -via_rule {{intersection: adjacent}{via_master: VIA_2x1}}
compile_pg -strategies {M2_mesh M1_rails} -via_rule {via_stdcell_mesh}

legalize_placement
check_pg_connectivity
check_pg_drc

####################################################################
#                                                                  #
#                            MCMM SETUP                            #
#                                                                  #
####################################################################
# Step 1: Clear all 
remove_scenarios -all
remove_modes -all
remove_corners -all

# Step 3: Define Modes
set m_constr(func) "scripts/mcmm/mcmm_m_func.tcl"
#set m_constr(test) "scripts/mcmm/mcmm_m_test.tcl"

# Step 4: Define Corners
set c_constr(slow) "scripts/mcmm/mcmm_c_saed32rvt_ss0p95v125c.tcl"
set c_constr(fast) "scripts/mcmm/mcmm_c_saed32rvt_ff0p95v125c.tcl"

# Step 5: Define Scenarios
set s_constr(func.slow) "work/slow/accel.sdc"
set s_constr(func.fast) "work/slow/accel.sdc"
#set s_constr(test.slow) "work/slow/accel.sdc"
#set s_constr(test.fast) "work/slow/accel.sdc"

# Step 6: Create Scenarios
# Slow
foreach m [array names m_constr] {
        create_mode $m
}

foreach c [array names c_constr] {
        create_corner $c
}

foreach s [array names s_constr] {
        lassign [split $s "."] m c
        create_scenario -name $s  -mode $m  -corner $c
}

# Common file contains port names for constraints
foreach m [array names m_constr] {
        current_mode $m
        source $m_constr($m)
}

foreach c [array names c_constr] {
        current_corner $c
        source $c_constr($c)
}

foreach s [array names s_constr] {
        current_scenario $s
        source $s_constr($s)
}

#configure scenario
set_scenario_status {*.slow} -hold false
set_scenario_status {*.slow *.fast} -leakage_power false -dynamic_power false
set_scenario_status {*.fast} -setup false

####################################################################
#                                                                  #
#                            PLACEMENT                             #
#                                                                  #
####################################################################

### Pre-placement stage ###
report_qor -summary

report_ideal_network -scenarios [all_scenarios]
report_ignored_layers
report_host_options
report_design -summary
#get_scan_chain_count
#check_scan_chain
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
check_legality

# report_congestion
report_utilization
# report_mv_design
report_timing
# report_timing -report_by scenario
# report_timing -report_by group


####################################################################
#                                                                  #
#                      CLOCK TREE SYNTHESIS                        #
#                                                                  #
####################################################################

# see which mode has violation in terms of hold uncertainty and setup uncertainty#######
current_mode
current_mode func

report_clocks
report_clocks -skew

report_clock_qor

report_scenario


####if got no ready for hold, turn this in case######
#set_scenario_status test.ff_125c -hold true

# If find that hold fixing is not sufficient, you can increase the effort
# set_app_options -name clock_opt.hold.effort -value high

# Enable clock reconvergence pessimism removal
set_app_options -name time.remove_clock_reconvergence_pessimism -value true



##########FINAL CHECKING PRIOR TO CTS

check_clock_trees

###################################
## Option A: Classic CTS
###################################

set_app_options -name clock_opt.flow.enable_ccd -value false
set_app_options -name cts.compile.enable_local_skew -value true
set_app_options -name cts.optimize.enable_local_skew -value true
clock_opt -to route_clock

report_clock_qor
# report_clock_qor -type local_skew -corner slow
# report_clock_qor -type area
# report_clock_qor -mode func -corner ss_125c -significant_digits 3

report_clock_qor -type robustness -mode func -corner ff_m40c -robustness_corner ss_125c

report_clock_timing -type skew -modes func -corners ss_125c -significant_digits 3

# # Post-CTS optimization
# ##################################

remove_clock_uncertainty [all_clocks] -scenarios [all_scenarios]

clock_opt -from final_opto
clock_opt -incremental


report_timing -mode func -corner fast -delay min
report_timing

save_block


####################################################################
#                                                                  #
#                            ROUTING                               #
#                                                                  #
####################################################################



#for checking the timing is acceptable for routing 
report_qor -summary

#check for any issues that might cause problems during routing
set_app_options -name route.common.verbose_level -value 1
check_design -checks pre_route_stage
set_app_options -name route.common.verbose_level -value 0


# Set application options for the specific routers
set_app_options -name route.global.timing_driven    -value true
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.timing_driven     -value true
set_app_options -name route.detail.timing_driven    -value true
set_app_options -name route.detail.force_max_number_iterations -value false


route_detail -incremental true -max_number_iterations 50
route_auto

check_routes

## Post-Route Timing Analysis

report_qor -summary

##Align ICC2 and PT timing analysis
set_app_options -name time.enable_ccs_rcv_cap -value true
#set_app_options name time.delay_calc_waveform_analysis_mode value full_design
set_app_options -name time.si_enable_analysis -value true

report_qor -summary
report_qor -summary -pba_mode path



## Post-Route Optimization
####################################
# power optimization, CCD, CTO are controlled via app options.
# report_app_options route_opt.*

route_opt
report_qor -summary

## To disable soft-rule-based timing optimization during ECO routing, uncomment the following.
#  This is to limit spreading which can touch multiple routes and impact convergence.
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false
set_app_options -name route_opt.flow.enable_ccd -value false

# For more accuracy switch to PBA now.
set_app_options -name time.pba_optimization_mode -value path

route_opt
report_qor -summary -pba_mode path



####################################################################
#                                                                  #
#                            ROUTING                               #
#                                                                  #
####################################################################

write_verilog results/accel_top.v
save_upf results/accel_top.upf
write_parasitics -f spef results/accel_parasitics.spef
