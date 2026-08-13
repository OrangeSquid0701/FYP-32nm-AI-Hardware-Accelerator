set LIB_ROOT /data/synopsys/lib/saed32nm/lib/

set DESIGN_NAME "accelerator_top"

#target library files
set RVT_LIB "saed32rvt_ss0p95v125c.db saed32rvt_ff0p95v125c.db"

set search_path "$search_path . \
                $LIB_ROOT/stdcell_rvt/db_nldm"

set_app_var link_path "* $RVT_LIB"

#set ADDITIONAL_LINK_LIB_FILES ""

set TECH_FILES "$LIB_ROOT/tech/milkyway/saed32nm_1p9m_mw.tf"

set MAP_FILE "$LIB_ROOT/tech/star_rc/saed32nm_tf_itf_tluplus.map"

set TLUPLUS_MAX_FILE "$LIB_ROOT/tech/star_rc/saed32nm_1p9m_Cmax.tluplus"

set TLUPLUS_MIN_FILE "$LIB_ROOT/tech/star_rc/saed32nm_1p9m_Cmin.tluplus"

set MW_POWER_NET       "VDD"
set MW_POWER_PORT      "VDD"
set MW_GROUND_NET      "VSS"
set MW_GROUND_PORT     "VSS"
set MIN_ROUTING_LAYER  "M1"
set MAX_ROUTING_LAYER  "M6"

