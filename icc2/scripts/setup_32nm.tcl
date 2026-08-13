set NDM_PATH "/data/synopsys/lib/saed32nm/lib"

set REF_LIBS " \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_c.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_pg_c.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_dlvl_v.ndm \
  $NDM_PATH/stdcell_rvt/ndm/saed32rvt_ulvl_v.ndm
"

create_lib ACCEL_LIB \
  -technology /data/synopsys/lib/saed32nm/lib/tech/milkyway/saed32nm_1p9m_mw.tf \
  -ref_libs $REF_LIBS

derive_design_level_via_regions

report_ref_lib
open_lib ACCEL_LIB

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

