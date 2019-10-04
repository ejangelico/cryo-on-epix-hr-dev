############################
# SIMULATION code
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules

# Load target's source code and constraints
#loadSource      -dir  "$::DIR_PATH/hdl/"
#loadConstraints -dir  "$::DIR_PATH/hdl/"

loadRuckusTcl $::env(TOP_DIR)/common/cryo


# set top moudule
set_property top {cryo_dune_tb} [get_filesets sim_1]
