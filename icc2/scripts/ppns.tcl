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
-layers {{{horizontal_layer: M7} {width: 4} {pitch: 50} {offset: 35}}}

create_pg_mesh_pattern mesh_pattern8 \
-layers {{{vertical_layer: M8} {width: 4} {pitch: 50} {offset: 35}}}

create_pg_mesh_pattern mesh_pattern_bottom \
-layers {{{vertical_layer: M2} {width: 4} {pitch: 50} {offset: 35}}}

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

