# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/surf"
loadRuckusTcl "$::DIR_PATH/epix-hr-core"
loadRuckusTcl "$::DIR_PATH/../common/$::env(COMMON_NAME)"
loadRuckusTcl "$::DIR_PATH/asic-rtl-lib"
