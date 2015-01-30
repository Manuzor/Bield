#!cmake

# Make sure the master script was included first.
if(NOT BIELD_INCLUDED)
  message(SEND_ERROR "You should include 'bield' first.")
endif()

### Include guard.
################################################################################
if(BIELD_CONFIG_INCLUDED)
  return()
endif()
set(BIELD_CONFIG_INCLUDED true)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(BIELD_OUTPUT_DIR "${CMAKE_BINARY_DIR}/Output" CACHE PATH
    "The directory in which to create the Bin and Lib folders in.")
set(BIELD_FILE_TEMPLATE_DIR "${CMAKE_MODULE_PATH}/templates" CACHE STRING
    "Directory containing all file templates used to generate new files listed in a CMakeLists.txt that does not yet exist on the filesystem.")
set(BIELD_COMPILE_WITH_HIGHEST_WARNING_LEVEL OFF CACHE BOOL
    "Whether to use the highest warning level when compiling. Good luck with that.")
set(BIELD_CREATE_MISSING_FILES ON CACHE BOOL
    "Whether to create files found in the bield_project's FILES variable that are missing from the file system. Does not work for the GLOB option, obviously...")

mark_as_advanced(BIELD_FILE_TEMPLATE_DIR
                 BIELD_CREATE_MISSING_FILES)

set(BIELD_DEFAULT_COMPILE_FLAGS "${CMAKE_CXX_FLAGS}" CACHE STRING "Compiler flags used in all builds")
set(BIELD_DEFAULT_LINK_FLAGS    "" CACHE STRING "Linker flags used in all builds")
mark_as_advanced(BIELD_DEFAULT_COMPILE_FLAGS
                 BIELD_DEFAULT_LINK_FLAGS)

# For all configuration types (Debug, Release, ...):
# set the default compiler and linker flags.
foreach(cfg ${CMAKE_CONFIGURATION_TYPES})
  string(TOUPPER "${cfg}" CFG)
  set(BIELD_DEFAULT_COMPILE_FLAGS_${CFG} "" CACHE STRING "Default compile flags used in ${cfg} builds only.")
  set(BIELD_DEFAULT_LINK_FLAGS_${CFG} "" CACHE STRING "Default link flags used in ${cfg} builds only.")
  mark_as_advanced(BIELD_DEFAULT_COMPILE_FLAGS_${CFG}
                   BIELD_DEFAULT_LINK_FLAGS_${CFG})
endforeach()

set(BIELD_OUTPUT_DIR_BIN "${BIELD_OUTPUT_DIR}/Bin")
set(BIELD_OUTPUT_DIR_LIB "${BIELD_OUTPUT_DIR}/Lib")

# the following is a modified and stripped version of
# CMAKE_GeneralConfig.txt taken from the ezEngine project.

## other configuration
#######################################################################

# Set the default build type.
if(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Debug CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  include(bield/bieldGeneralConfig_Windows)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CURRENT_OSX_VERSION)
  include(bield/bieldGeneralConfig_OSX)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  include(bield/bieldGeneralConfig_Linux)
else()
  bield_fatal("Unsupported platform '${CMAKE_SYSTEM_NAME}'.")
endif()
