# Define the location of the CASTRO top directory,
# if not already defined by an environment variable.

CASTRO_DIR := ../../

# Location of this directory. Useful if
# you're trying to compile this from another location.

TEST_DIR = $(CASTRO_DIR)/Exec/KH

PRECISION  ?= DOUBLE
PROFILE    ?= FALSE

DEBUG      ?= FALSE

DIM        ?= 2

COMP	   ?= gcc
FCOMP	   ?= gfortran

USE_MPI    ?= FALSE
USE_OMP    ?= FALSE

DIMENSION_AGNOSTIC = TRUE

DEFINES += -DNUM_ADV=1

# This sets the EOS directory in Castro/EOS
EOS_dir     ?= gamma_law

# This sets the network directory in Castro/Networks
Network_dir ?= general_null
GENERAL_NET_INPUTS ?= $(CASTRO_DIR)/Networks/$(Network_dir)/gammalaw.net

Bpack   += $(TEST_DIR)/Make.package
Blocs   += $(TEST_DIR)/.

include $(CASTRO_DIR)/Exec/Make.Castro
