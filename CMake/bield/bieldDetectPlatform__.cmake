#!cmake

### Include guard
################################################################################
if(BIELD_DETECT_PLATFORM_INCLUDED)
  return()
endif()
set(BIELD_DETECT_PLATFORM_INCLUDED true)

### Cache variables
################################################################################
set(BIELD_PLATFORM_WINDOWS off CACHE INTERNAL
    "Running on Windows?" FORCE)
set(BIELD_PLATFORM_LINUX off CACHE INTERNAL
    "Running on Linux?" FORCE)
set(BIELD_PLATFORM_OSX off CACHE INTERNAL
    "Running on OSX?" FORCE)

set(BIELD_PLATFORM_POSIX off CACHE INTERNAL
    "Whether the platform supports posix or not." FORCE)

set(BIELD_PLATFORM_ABBR off CACHE INTERNAL
    "Abbreveation for the current platform." FORCE)

### Functions / Macros
################################################################################

macro(bield_detect_platform)
  if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # Windows
    bield_log(1 "Platform is Windows (BIELD_PLATFORM_WINDOWS)")
    set(BIELD_PLATFORM_WINDOWS ON)
    set(BIELD_PLATFORM_ABBR "Win")

  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CURRENT_OSX_VERSION)
    # OS X
    bield_log(1 "Platform is OS X (BIELD_PLATFORM_OSX, BIELD_PLATFORM_POSIX)")
    set(BIELD_PLATFORM_OSX ON)
    set(BIELD_PLATFORM_POSIX ON)
    set(BIELD_PLATFORM_ABBR "Osx")

  elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # Linux
    bield_log(1 "Platform is Linux (BIELD_PLATFORM_LINUX, BIELD_PLATFORM_POSIX)")  
    set(BIELD_PLATFORM_LINUX ON)
    set(BIELD_PLATFORM_POSIX ON)
    set(BIELD_PLATFORM_ABBR "Linux")
    
  else()
    bield_fatal("Platform '${CMAKE_SYSTEM_NAME}' is not supported! Please extend bieldDetectPlatform.cmake.")
  endif()
endmacro()
