# Step 1: Clear all 
remove_scenarios -all
remove_modes -all
remove_corners -all

# Step 3: Define Modes
set m_constr(func) "scripts/mcmm/mcmm_m_func.tcl"
#set m_constr(test) "scripts/mcmm/mcmm_m_test.tcl"

# Step 4: Define Corners
set c_constr(slow) "scripts/mcmm/mcmm_c_saed32rvt_ss0p95v125c.tcl"
#set c_constr(fast) "scripts/mcmm/mcmm_c_saed14hvt_ff0p72v125c.tcl"

# Step 5: Define Scenarios
set s_constr(func.slow) "work/slow/accel.sdc"
#set s_constr(func.fast) "work/slow/accel.sdc"
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
