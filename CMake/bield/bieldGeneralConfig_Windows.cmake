#!cmake

### Cache variables
################################################################################
set(BIELD_PLATFORM_WINDOWS ON CACHE INTERNAL
    "Running on Windows." FORCE)

set(BIELD_COMPILER_MSVC OFF CACHE INTERNAL
    "Using the Microsoft Visual C++ Compiler (MSVC)." FORCE)

set(BIELD_COMPILER_MSVC_2010 OFF CACHE INTERNAL
    "Using the Microsoft Visual C Compiler (MSVC) version 100 (2010)." FORCE)

set(BIELD_COMPILER_MSVC_2012 OFF CACHE INTERNAL
    "Using the Microsoft Visual C Compiler (MSVC) version 110 (2012)." FORCE)

set(BIELD_COMPILER_MSVC_2013 OFF CACHE INTERNAL
    "Using the Microsoft Visual C Compiler (MSVC) version 120 (2013)." FORCE)

set(BIELD_ARCHITECTURE_32BIT OFF CACHE INTERNAL
    "Compiling for a 32 bit architecture?")

set(BIELD_ARCHITECTURE_64BIT OFF CACHE INTERNAL
    "Compiling for a 64 bit architecture?")

set(BIELD_USE_PCH ON CACHE BOOL
    "Whether to use precompiled headers or not. On by default on Windows.")

### Functions / Macros
################################################################################
bield_todo("Move PCH related stuff to bieldGeneralConfig_Windows.cmake.")

### Collect data.
################################################################################
# Info that will be logged once all information is gathered.
set(INFO "Platform: Windows")

# Supported windows generators
if(MSVC)
  # Visual Studio (All VS generators define MSVC)
  set(BIELD_COMPILER_MSVC ON)

  # Specific compiler
  if(MSVC12)
    set(BIELD_COMPILER_MSVC_2013 ON)
    set(GENERATOR_PREFIX "VisualStudio2013")
  elseif(MSVC11)
    set(BIELD_COMPILER_MSVC_2012 ON)
    set(GENERATOR_PREFIX "VisualStudio2012")
  elseif(MSVC10)
    set(BIELD_COMPILER_MSVC_2010 ON)
    set(GENERATOR_PREFIX "VisualStudio2010")
  else()
    bield_fata("Unsupported compiler version")
  endif()

  # Architecture (32/64 bit)
  if(CMAKE_CL_64)
    set(BIELD_ARCHITECTURE_64BIT ON)
    set(BIELD_ARCHITECTURE_STRING "64")
  else()
    set(BIELD_ARCHITECTURE_32BIT ON)
    set(BIELD_ARCHITECTURE_STRING "32")
  endif()

  set(INFO "${INFO} ${BIELD_ARCHITECTURE_STRING} bit using ${GENERATOR_PREFIX}")

else()
  bield_fatal("Generator '${CMAKE_GENERATOR}' is not supported on Windows!.")
endif()

### Process collected data.
################################################################################
bield_log(1 "${INFO}")

set(BIELD_OUTPUT_PREFIX_BIN "${BIELD_OUTPUT_DIR}/Bin/Win${GENERATOR_PREFIX}")
set(BIELD_OUTPUT_PREFIX_LIB "${BIELD_OUTPUT_DIR}/Lib/Win${GENERATOR_PREFIX}")

# Iterate over all configuration types and set appropriate output dirs.
# Note: None is included as a default value.
foreach(cfg None ${CMAKE_CONFIGURATION_TYPES})
  string(TOUPPER "${cfg}" CFG) # Debug => DEBUG

  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CFG} "${BIELD_OUTPUT_PREFIX_BIN}${cfg}${BIELD_ARCHITECTURE_STRING}")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CFG} "${BIELD_OUTPUT_PREFIX_LIB}${cfg}${BIELD_ARCHITECTURE_STRING}")
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CFG} "${BIELD_OUTPUT_PREFIX_LIB}${cfg}${BIELD_ARCHITECTURE_STRING}")
endforeach()

### Compile flags
################################################################################
if(BIELD_COMPILER_MSVC)
  if(BIELD_COMPILE_WITH_HIGHEST_WARNING_LEVEL)
    # Highest warning level.
    set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /W4")
  endif()

  # Multi-threaded compilation in all configurations.
  set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /MP")
  # Treat warnings as errors in all configurations.
  set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /WX")
  # Disable RTTI in all configurations.
  set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /GR-")
  # Use fast floating point model in all configurations.
  set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /fp:fast")

  if(BIELD_ARCHITECTURE_32BIT)
    # Enable SSE2 on 32 bit (incompatible with /fp:except)
    set(BIELD_DEFAULT_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS} /arch:SSE2")
  endif()

  ### Other configurations
  ##############################################################################
  # Minimal rebuild
  set(BIELD_DEFAULT_COMPILE_FLAGS_DEBUG "${BIELD_DEFAULT_COMPILE_FLAGS_DEBUG} /Zi /Gm")

  if(MSVC11)
    # Enable debugging optimized code (release builds)
    set(BIELD_DEFAULT_COMPILE_FLAGS_RELEASE        "${BIELD_DEFAULT_COMPILE_FLAGS_RELEASE} /d2Zi+")
    set(BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO} /d2Zi+")
  endif()

  if(MSVC12)
    # Enable debugging optimized code (release builds)
    set(BIELD_DEFAULT_COMPILE_FLAGS_RELEASE        "${BIELD_DEFAULT_COMPILE_FLAGS_RELEASE} /Zo")
    set(BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO} /Zo")
  endif()

  # Maximum optimization, auto-inlining, intrinsic functions
  set(BIELD_DEFAULT_COMPILE_FLAGS_RELEASE        "${BIELD_DEFAULT_COMPILE_FLAGS_RELEASE} /Ox /Ob2 /Oi")
  set(BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_COMPILE_FLAGS_RELWITHDEBINFO} /Ox /Ob2 /Oi")
endif()

### Link flags
################################################################################
if(BIELD_COMPILER_MSVC)
  
  # Disable incremental linking
  set(BIELD_DEFAULT_LINK_FLAGS_RELEASE        "${BIELD_DEFAULT_LINK_FLAGS_RELEASE} /INCREMENTAL:NO")
  set(BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO} /INCREMENTAL:NO")

  # Remove unreferenced data (incompatible with incremental build)
  set(BIELD_DEFAULT_LINK_FLAGS_RELEASE        "${BIELD_DEFAULT_LINK_FLAGS_RELEASE} /OPT:REF")
  set(BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO} /OPT:REF")

  # Not sure what it does but ezEngine is using it... (incompatible with incremental build)
  set(BIELD_DEFAULT_LINK_FLAGS_RELEASE        "${BIELD_DEFAULT_LINK_FLAGS_RELEASE} /OPT:ICF")
  set(BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO "${BIELD_DEFAULT_LINK_FLAGS_RELWITHDEBINFO} /OPT:ICF")
endif()
