#!cmake
################################################################################
### This script basically just includes all dependencies to make Bield       ###
### work properly. It also guards against multiple inclusions during the     ###
### same CMake generation phase.                                             ###
################################################################################

# Make sure users include this script after their first call to project(...)
if(NOT CMAKE_SYSTEM_NAME)
  message(SEND_ERROR "You have to include bield after the first call to project(...).")
endif()

# Include guard.
if(BIELD_INCLUDED)
  return()
endif()
set(BIELD_INCLUDED true)

####################
### Dependencies ###
####################

# Used for easier parsing of optional arguments passed to bield_ functions.
# Shipped with CMake itself.
include(CMakeParseArguments)

# Used to print all properties of a target.
# Should be located right next to this script (bield.cmake).
include(echoTargetProperties)

#####################
### Bield scripts ###
#####################

# Bield script that defines all logging-related stuff.
# Most importantly the function bield_log(123, ""), which should be used
# instead of message(STATUS "").
include(bield/bieldLogging)

# Include the config file which determines the platform, compiler, etc.
# It also exposes some configuration variables to the user.
include(bield/bieldGeneralConfig)

# Include the file which implements all bield_ utility functions.
include(bield/bieldUtilities)
