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

source scripts/ppns.tcl
