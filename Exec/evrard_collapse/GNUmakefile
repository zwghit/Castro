# Define the location of the CASTRO top directory,
# if not already defined by an environment variable.

CASTRO_DIR := ../../

# Location of this directory. Useful if
# you're trying to compile this from another location.

TEST_DIR = $(CASTRO_DIR)/Exec/evrard_collapse

PRECISION  = DOUBLE
PROFILE    = FALSE

DEBUG      = FALSE

DIM        = 3

COMP	   = gcc
FCOMP	   = gfortran

USE_MPI    = FALSE
USE_OMP    = FALSE

USE_GRAV   = TRUE

ifdef MICROPHYSICS_DIR
  # This sets the EOS directory in $(MICROPHYSICS_DIR)/eos
  EOS_dir     := gamma_law_general
else
  $(error Error: This problem requires the Microphysics repository. Please ensure that you have downloaded it and set $$MICROPHYSICS_DIR appropriately)
endif

# This sets the network directory in Castro/Networks
Network_dir := general_null
GENERAL_NET_INPUTS = $(CASTRO_DIR)/Networks/$(Network_dir)/gammalaw.net

Bpack   += $(TEST_DIR)/Make.package
Blocs   += $(TEST_DIR)

include $(CASTRO_DIR)/Exec/Make.Castro
