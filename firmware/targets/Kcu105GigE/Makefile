# Define target output
target: prom

# Define Firmware Version Number
export PRJ_VERSION = 0x00000008

# Define target part
export PRJ_PART = XCKU040-FFVA1156-2-E

# COMM_TYPE is defined by application
export COMM_TYPE = pgp3

# COMMON_NAME is defined by application
export COMMON_NAME = cryo

# Define if you want to build the user Microblaze core
export BUILD_MB_CORE = 0

# Define if you want to build the DDR MIG core
export BUILD_MIG_CORE = 0

# Define if this is FSBL PROM address
export PROM_FSBL = 0

# Define if you want to remove unused source code
export REMOVE_UNUSED_CODE = 0

# # Define the Microblaze source path
# export SDK_SRC_PATH = $(PROJ_DIR)/../../../common/core/src

# Whether to use the on-board PHY (connected to the RJ-45 jack)
# or an SFP module for ethernet connectivity.
# Must be 1 or 0
export USE_RJ45_ETH = 1

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../..)

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk
