#!cmake

# Make sure the master script was included first.
if(NOT BIELD_INCLUDED)
  message(SEND_ERROR "You should include 'bield' first.")
endif()

# Include guard.
if(BIELD_CONFIG_INCLUDED)
  return()
endif()
set(BIELD_CONFIG_INCLUDED true)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(BIELD_USE_PCH ON CACHE BOOL
    "Whether to use precompiled headers (if available) or not.")
set(BIELD_OUTPUT_DIR "${CMAKE_BINARY_DIR}" CACHE PATH
    "The directory in which to create the bin and lib folders in.")
set(BIELD_FILE_TEMPLATE_DIR "${CMAKE_MODULE_PATH}/templates" CACHE STRING
    "Directory containing all file templates used to generate new files listed in a CMakeLists.txt that does not yet exist on the filesystem.")
set(BIELD_STRICT_WARNINGS OFF CACHE BOOL
    "Whether to use the highest warning level.")
set(BIELD_CREATE_MISSING_FILES ON CACHE BOOL
    "Whether to create files found in the bield_project's FILES variable that are missing from the file system.")

set(BIELD_COMPILER_SETTINGS_ALL     "" CACHE STRING "Compiler settings used in all builds")
set(BIELD_COMPILER_SETTINGS_RELEASE "" CACHE STRING "Compiler settings used in release builds only")
set(BIELD_COMPILER_SETTINGS_DEBUG   "" CACHE STRING "Compiler settings used in debug builds only")
set(BIELD_LINKER_SETTINGS_ALL       "" CACHE STRING "Linker settings used in all builds")
set(BIELD_LINKER_SETTINGS_RELEASE   "" CACHE STRING "Linker settings used in release builds only")
set(BIELD_LINKER_SETTINGS_DEBUG     "" CACHE STRING "Linker settings used in debug builds only")

mark_as_advanced(BIELD_FILE_TEMPLATE_DIR
                 BIELD_CREATE_MISSING_FILES

                 BIELD_COMPILER_SETTINGS_ALL
                 BIELD_COMPILER_SETTINGS_RELEASE
                 BIELD_COMPILER_SETTINGS_DEBUG
                 BIELD_LINKER_SETTINGS_ALL
                 BIELD_LINKER_SETTINGS_RELEASE
                 BIELD_LINKER_SETTINGS_DEBUG)

set(BIELD_OUTPUT_DIR_BIN "${BIELD_OUTPUT_DIR}/bin")
set(BIELD_OUTPUT_DIR_LIB "${BIELD_OUTPUT_DIR}/lib")

# the following is a modified and stripped version of
# CMAKE_GeneralConfig.txt taken from the ezEngine project.

## other configuration
#######################################################################

# setthe default build type
if(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Debug CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
endif()

#########################################################################################
## Detects the current platform

set(BIELD_PLATFORM_PREFIX "")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Windows
  bield_log(1 "Platform is Windows (BIELD_BUILDSYSTEM_PLATFORM_WINDOWS)")
  set(BIELD_BUILDSYSTEM_PLATFORM_WINDOWS ON)
  set(BIELD_PLATFORM_PREFIX "Win")
  
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CURRENT_OSX_VERSION)
  # OS X
  bield_log(1 "Platform is OS X (BIELD_BUILDSYSTEM_PLATFORM_OSX, BIELD_BUILDSYSTEM_PLATFORM_POSIX)")
  set(BIELD_BUILDSYSTEM_PLATFORM_OSX ON)
  set(BIELD_BUILDSYSTEM_PLATFORM_POSIX ON)
  set(BIELD_PLATFORM_PREFIX "Osx")
  
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  # Linux
  bield_log(1 "Platform is Linux (BIELD_BUILDSYSTEM_PLATFORM_LINUX, BIELD_BUILDSYSTEM_PLATFORM_POSIX)")  
  set(BIELD_BUILDSYSTEM_PLATFORM_LINUX ON)
  set(BIELD_BUILDSYSTEM_PLATFORM_POSIX ON)
  set(BIELD_PLATFORM_PREFIX "Linux")
  
else()
  bield_fatal("Platform '${CMAKE_SYSTEM_NAME}' is not supported! Please extend bieldConfig.cmake.")
endif()


#########################################################################################
## Detects the current build-system / generator

set(BIELD_BUILDSYSTEM_PREFIX "")

if(BIELD_BUILDSYSTEM_PLATFORM_WINDOWS)
  # Supported windows generators
  if(MSVC)
    # Visual Studio (All VS generators define MSVC)
    bield_log(1 "Buildsystem is MSVC (BIELD_BUILDSYSTEM_MSVC)")
    set(BIELD_BUILDSYSTEM_MSVC ON)
    set(BIELD_BUILDSYSTEM_PREFIX "Vs")
    set(BIELD_BUILDSYSTEM_CONFIGURATION $<CONFIGURATION>)
  else()
    bield_fatal("Generator '${CMAKE_GENERATOR}' is not supported on Windows! Please extend bieldConfig.cmake.")
  endif()
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_OSX)
  # Supported OSX generators
  if(CMAKE_GENERATOR STREQUAL "Xcode")
    # XCODE
    bield_log(1 "Buildsystem is Xcode (BIELD_BUILDSYSTEM_XCODE)")
    set(BIELD_BUILDSYSTEM_XCODE ON)
    set(BIELD_BUILDSYSTEM_PREFIX "Xcode")
    set(BIELD_BUILDSYSTEM_CONFIGURATION $<CONFIGURATION>)
  elseif(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    # Unix Makefiles (for QtCreator etc.)
    bield_log(1 "Buildsystem is Make (BIELD_BUILDSYSTEM_MAKE)")
    set(BIELD_BUILDSYSTEM_MAKE ON)
    set(BIELD_BUILDSYSTEM_PREFIX "Make")
    set(BIELD_BUILDSYSTEM_CONFIGURATION ${CMAKE_BUILD_TYPE})
  else()
    bield_fatal("Generator '${CMAKE_GENERATOR}' is not supported on OS X! Please extend bieldConfig.cmake.")
  endif()
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_LINUX)
  if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    # Unix Makefiles (for QtCreator etc.)
    bield_log(1 "Buildsystem is Make (BIELD_BUILDSYSTEM_MAKE)")
    set(BIELD_BUILDSYSTEM_MAKE ON)
    set(BIELD_BUILDSYSTEM_PREFIX "Make")
    set(BIELD_BUILDSYSTEM_CONFIGURATION ${CMAKE_BUILD_TYPE})
  else()
    bield_fatal("Generator '${CMAKE_GENERATOR}' is not supported on Linux! Please extend bieldConfig.cmake.")
  endif()
  
else()
  bield_fatal("Platform '${CMAKE_SYSTEM_NAME}' has not setup the supported generators. Please extend bieldConfig.cmake.")
endif()

#########################################################################################
## Detects the current compiler

set(BIELD_COMPILER_POSTFIX "")

if(BIELD_BUILDSYSTEM_MSVC)
  # Visual Studio Compiler
  bield_log(1 "Compiler is MSVC (BIELD_BUILDSYSTEM_COMPILER_MSVC)")
  set(BIELD_BUILDSYSTEM_COMPILER_MSVC ON)
  
  if(MSVC12)
    bield_log(1 "Compiler is Visual Studio 120 (2013) (BIELD_BUILDSYSTEM_COMPILER_MSVC_120)")
    set(BIELD_BUILDSYSTEM_COMPILER_MSVC_120 ON)
    set(BIELD_COMPILER_POSTFIX "120")
  elseif(MSVC11)
    bield_log(1 "Compiler is Visual Studio 110 (2012) (BIELD_BUILDSYSTEM_COMPILER_MSVC_110)")
    set(BIELD_BUILDSYSTEM_COMPILER_MSVC_110 ON)
    set(BIELD_COMPILER_POSTFIX "110")
  elseif(MSVC10)
    bield_log(1 "Compiler is Visual Studio 100 (2010) (BIELD_BUILDSYSTEM_COMPILER_MSVC_100)")
    set(BIELD_BUILDSYSTEM_COMPILER_MSVC_100 ON)
    set(BIELD_COMPILER_POSTFIX "100")
  else()
    bield_fatal("Compiler for generator '${CMAKE_GENERATOR}' is not supported on MSVC! Please extend bieldConfig.cmake.")
  endif()
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_OSX)
  # Currently all are clang by default.
  # We should probably make this more idiot-proof in case someone actually changes the compiler to gcc.
  bield_log(1 "Compiler is clang (BIELD_BUILDSYSTEM_COMPILER_CLANG)")  
  set(BIELD_BUILDSYSTEM_COMPILER_CLANG ON)
  set(BIELD_COMPILER_POSTFIX "Clang")
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_LINUX)
  # Currently all are gcc by default. See OSX comment.
  bield_log(1 "Compiler is gcc (BIELD_BUILDSYSTEM_COMPILER_GCC)")  
  set(BIELD_BUILDSYSTEM_COMPILER_GCC ON)
  set(BIELD_COMPILER_POSTFIX "Gcc")
  
else()
  bield_fatal("Compiler for generator '${CMAKE_GENERATOR}' is not supported on '${CMAKE_SYSTEM_NAME}'. Please extend bieldConfig.cmake.")
endif()


#########################################################################################
## Detects the current architecture

set(BIELD_ARCHITECTURE_POSTFIX "")

if(BIELD_BUILDSYSTEM_PLATFORM_WINDOWS AND BIELD_BUILDSYSTEM_COMPILER_MSVC)
  # Detect 64-bit builds for MSVC.
  if(CMAKE_CL_64)
    bield_log(1 "Platform is 64-Bit (BIELD_BUILDSYSTEM_PLATFORM_64BIT)")
    set(BIELD_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(BIELD_ARCHITECTURE_POSTFIX "64")
  else()
    bield_log(1 "Platform is 32-Bit (BIELD_BUILDSYSTEM_PLATFORM_32BIT)")
    set(BIELD_BUILDSYSTEM_PLATFORM_32BIT ON)
    set(BIELD_ARCHITECTURE_POSTFIX "32")
  endif()
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_OSX AND BIELD_BUILDSYSTEM_COMPILER_CLANG)
  # OS X always has 32/64 bit support in the project files and the user switches on demand.
  # However, we do not support 32 bit with our current build configuration so we throw an error on 32-bit systems.
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    bield_log(1 "Platform is 64-Bit (BIELD_BUILDSYSTEM_PLATFORM_64BIT)")
    set(BIELD_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(BIELD_ARCHITECTURE_POSTFIX "64")
  else()
    bield_fatal("32-Bit is not supported on OS X!")
  endif()
  
elseif(BIELD_BUILDSYSTEM_PLATFORM_LINUX AND BIELD_BUILDSYSTEM_COMPILER_GCC)
  # Detect 64-bit builds for Linux, no other way than checking CMAKE_SIZEOF_VOID_P.
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    bield_log(1 "Platform is 64-Bit (BIELD_BUILDSYSTEM_PLATFORM_64BIT)")
    set(BIELD_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(BIELD_ARCHITECTURE_POSTFIX "64")
  else()
    bield_log(1 "Platform is 32-Bit (BIELD_BUILDSYSTEM_PLATFORM_32BIT)")
    set(BIELD_BUILDSYSTEM_PLATFORM_32BIT ON)
    set(BIELD_ARCHITECTURE_POSTFIX "32")
  endif()
  
else()
  bield_fatal("Architecture could not be determined. Please extend bieldConfig.cmake.")
endif()

## tell cmake where to build our stuff to
#######################################################################

set(BIELD_OUTPUT_LIB_DEBUG          "${BIELD_OUTPUT_DIR_LIB}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}Debug${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_LIB_RELEASE        "${BIELD_OUTPUT_DIR_LIB}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}Release${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_LIB_MINSIZE        "${BIELD_OUTPUT_DIR_LIB}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}MinSize${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_LIB_RELWITHDEBINFO "${BIELD_OUTPUT_DIR_LIB}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}RelWithDebInfo${BIELD_ARCHITECTURE_POSTFIX}")
                                                       
set(BIELD_OUTPUT_BIN_DEBUG          "${BIELD_OUTPUT_DIR_BIN}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}Debug${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_BIN_RELEASE        "${BIELD_OUTPUT_DIR_BIN}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}Release${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_BIN_MINSIZE        "${BIELD_OUTPUT_DIR_BIN}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}MinSize${BIELD_ARCHITECTURE_POSTFIX}")
set(BIELD_OUTPUT_BIN_RELWITHDEBINFO "${BIELD_OUTPUT_DIR_BIN}/${BIELD_PLATFORM_PREFIX}${BIELD_BUILDSYSTEM_PREFIX}${BIELD_COMPILER_POSTFIX}RelWithDebInfo${BIELD_ARCHITECTURE_POSTFIX}")

bield_log(1 "source dir:     ${CMAKE_SOURCE_DIR}")
bield_log(1 "bin output dir: ${BIELD_OUTPUT_DIR_BIN}")
bield_log(1 "lib output dir: ${BIELD_OUTPUT_DIR_LIB}")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY                 "${BIELD_OUTPUT_BIN_DEBUG}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG           "${BIELD_OUTPUT_BIN_DEBUG}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE         "${BIELD_OUTPUT_BIN_RELEASE}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL      "${BIELD_OUTPUT_BIN_MINSIZE}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${BIELD_OUTPUT_BIN_RELWITHDEBINFO}")

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY                 "${BIELD_OUTPUT_LIB_DEBUG}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG           "${BIELD_OUTPUT_LIB_DEBUG}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE         "${BIELD_OUTPUT_LIB_RELEASE}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL      "${BIELD_OUTPUT_LIB_MINSIZE}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${BIELD_OUTPUT_LIB_RELWITHDEBINFO}")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY                 "${BIELD_OUTPUT_LIB_DEBUG}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG           "${BIELD_OUTPUT_LIB_DEBUG}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE         "${BIELD_OUTPUT_LIB_RELEASE}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL      "${BIELD_OUTPUT_LIB_MINSIZE}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${BIELD_OUTPUT_LIB_RELWITHDEBINFO}")

## compiler specific settings
#######################################################################

if(BIELD_BUILDSYSTEM_COMPILER_MSVC)
  # Enable minimal rebuild
  set(BIELD_COMPILER_SETTINGS_DEBUG "${BIELD_COMPILER_SETTINGS_DEBUG} /Gm")
  # enable multi-threaded compilation
  set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /MP")
  # disable RTTI
  set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /GR-")
  # use fast floating point model
  set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /fp:fast")
  # enable floating point exceptions
  #set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /fp:except")

  # enable strict warnings
  if(BIELD_STRICT_WARNINGS)
    set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /W4")
  endif()
  # treat warnings as errors
  set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /WX")

  if(BUILDSYSTEM_PLATFORM_32BIT)
    # enable SSE2 (incompatible with /fp:except)
    set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /arch:SSE2")
    
    if(MSVC10)
      # enable static code analysis, only works on 32 Bit builds
      # (may cause compile errors when combined with Qt, disabled for the time being)
      #set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /analyze")    
      #message (STATUS "Enabling static code analysis.")
    endif()
  endif()
  
  if(MSVC11 OR MSVC12)
    #set(BIELD_COMPILER_SETTINGS_ALL "${BIELD_COMPILER_SETTINGS_ALL} /analyze")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /d2Zi+")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /d2Zi+")
  endif()

  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /Ox /Ob2 /Oi")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox /Ob2 /Oi")
  
  set(BIELD_LINKER_SETTINGS_RELEASE "${BIELD_LINKER_SETTINGS_RELEASE} /INCREMENTAL:NO")
  # Remove unreferenced data (does not work together with incremental build)
  set(BIELD_LINKER_SETTINGS_RELEASE "${BIELD_LINKER_SETTINGS_RELEASE} /OPT:REF")
  # Don't know what it does, but Clemens wants it :-) (does not work together with incremental build)
  set(BIELD_LINKER_SETTINGS_RELEASE "${BIELD_LINKER_SETTINGS_RELEASE} /OPT:ICF")
  
elseif(BIELD_BUILDSYSTEM_COMPILER_CLANG)
  # Enable c++11 features
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++")
elseif(BIELD_BUILDSYSTEM_COMPILER_GCC)
  # dynamic linking will fail without fPIC (plugins)
  # Wno-enum-compare removes all annoying enum cast warnings
  # std=c++11 is - well needed for c++11.
  # gdwarf-3 will use the old debug info which is compatible with older gdb versions.
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wno-enum-compare -std=c++11 -mssse3 -mfpmath=sse -gdwarf-3")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -gdwarf-3")
  
else()
  bield_fatal("No settings are defined for the selected compiler. Please extend bieldConfig.cmake.")
endif()
