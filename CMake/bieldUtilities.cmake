#!cmake

# Make sure the master script was included first.
if(NOT BIELD_INCLUDED)
  message(SEND_ERROR "You should include 'bield' first.")
endif()

# Include guard.
if(BIELD_UTILITIES_INCLUDED)
  return()
endif()
set(BIELD_UTILITIES_INCLUDED true)

if(NOT BIELD_CONFIG_INCLUDED)
  message(SEND_ERROR "General config was not included yet!")
endif()

# helper functions
################################################################################

function(bield_msvc_add_pch_flags PCH)
  bield_indent_log_prefix("(pch)")
  cmake_parse_arguments(PCH "" PREFIX "" ${ARGN})

  get_filename_component(PCH_DIR "${PCH}" DIRECTORY)
  get_filename_component(PCH     "${PCH}" NAME_WE)

  if(PCH_PREFIX)
    set(PCH_PREFIX "${PCH_PREFIX}/")
  endif()

  set(PCH_CREATE_FLAG "/Yc${PCH_PREFIX}${PCH}.h")
  set(PCH_USE_FLAG    "/Yu${PCH_PREFIX}${PCH}.h")

  # if the pch is not on the top-level, prepend the directory
  if(NOT PCH_DIR STREQUAL "")
    set(PCH "${PCH_DIR}/${PCH_NAME}")
  endif()

  bield_log(3 "adding source property '${PCH_CREATE_FLAG}': ${PCH}.cpp")
  # add the necessary compiler flags to pch itself
  set_source_files_properties("${PCH}.cpp" PROPERTIES COMPILE_FLAGS "${PCH_CREATE_FLAG}")

  foreach(SRC_FILE ${ARGN})
    # we ignore the precompiled header and the corresponding .cpp file itself
    if(NOT SRC_FILE STREQUAL "${PCH}.h" AND NOT SRC_FILE STREQUAL "${PCH}.cpp")
      get_filename_component(SRC_EXT "${SRC_FILE}" EXT)
      # only apply the 'use' flag on .cpp files
      if("${SRC_EXT}" STREQUAL ".cpp")
        get_filename_component(SRC_NAME "${SRC_FILE}" NAME_WE)
        bield_log(3 "adding source property '${PCH_USE_FLAG}': ${SRC_FILE}")
        set_source_files_properties ("${SRC_FILE}" PROPERTIES COMPILE_FLAGS "${PCH_USE_FLAG}")
      endif()
    endif()
  endforeach()
endfunction(bield_msvc_add_pch_flags)

function(bield_group_sources_by_file_system)
  bield_indent_log_prefix("(source grouping)")
  foreach(SRC_FILE ${ARGN})
    get_filename_component(SRC_DIR "${SRC_FILE}" DIRECTORY)
    string(REPLACE "/" "\\" SRC_DIR "${SRC_DIR}")
    source_group("${SRC_DIR}" FILES "${SRC_FILE}")
    bield_log(3 "${SRC_DIR} => ${SRC_FILE}")
  endforeach()
endfunction(bield_group_sources_by_file_system)

function(bield_add_sfml TARGET_NAME)
  set(SFML_ROOT "$ENV{SFML_ROOT}" CACHE PATH
      "Path to the (installed) SFML root directory. This variable can be set manually if cmake fails to find SFML automatically.")
  find_package(SFML ${ARGN})
  if(SFML_FOUND)
    include_directories("${SFML_INCLUDE_DIR}")
    target_link_libraries(${TARGET_NAME} ${SFML_LIBRARIES})
  else()
    bield_log(0 "Please specify SFML_ROOT as either a cmake cache variable or an environment variable.")
  endif()

  # copy DLLs only on windows
  if(MSVC)
    # copy SFML dlls to output dir as a post-build command
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                       COMMAND ${CMAKE_COMMAND} -E copy_directory
                       "${SFML_ROOT}/bin"
                       $<TARGET_FILE_DIR:${TARGET_NAME}>)
  endif()
endfunction(bield_add_sfml)

function(bield_add_ezEngine TARGET_NAME)
  cmake_parse_arguments(ezEngine "POST_BUILD_COPY_DLLS" "" "" ${ARGN})
  if(ezEngine_POST_BUILD_COPY_DLLS)
    set(ezEngine_POST_BUILD_COPY_DLLS "${TARGET_NAME}")
  endif()
  find_package(ezEngine ${ezEngine_UNPARSED_ARGUMENTS})

  if(ezEngine_FOUND)
    include_directories("${ezEngine_INCLUDE_DIR}")
    target_link_libraries("${TARGET_NAME}" ${ezEngine_LIBRARIES})
  endif()
endfunction()

function(bield_add_packages TARGET_NAME)
  bield_indent_log_prefix("(packages)")
  cmake_parse_arguments(PKG "krEngine" "" "SFML;ezEngine" ${ARGN})

  if(PKG_UNPARSED_ARGUMENTS)
    bield_warning_unparsed_args("unparsed arguments: ${PKG_UNPARSED_ARGUMENTS}")
  endif()

  if(PKG_SFML)
    bield_log(1 "adding SFML")
    bield_log(2 "args: ${PKG_SFML}")
    bield_add_sfml("${TARGET_NAME}" "${PKG_SFML}")
  endif()

  if(PKG_ezEngine)
    bield_log(1 "adding ezEngine")
    bield_log(2 "args: ${PKG_ezEngine}")
    bield_add_ezEngine("${TARGET_NAME}" "${PKG_ezEngine}")
  endif()

  if(PKG_krEngine)
    target_link_libraries("${TARGET_NAME}" krEngine)
    foreach(CFG DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
      get_target_property(krEngine_LIBRARY_OUTPUT_DIR krEngine LIBRARY_OUTPUT_DIRECTORY_${CFG})
      link_directories("${krEngine_LIBRARY_OUTPUT_DIR}")
    endforeach()
  endif()

endfunction(bield_add_packages)

# chooses a file template based on the given FILE_EXTENSION
function(bield_get_file_template FILE_EXTENSION OUTPUT_VARIABLE)
  if("${FILE_EXTENSION}" STREQUAL ".h" OR
     "${FILE_EXTENSION}" STREQUAL ".hpp")
    set(${OUTPUT_VARIABLE} "${BIELD_FILE_TEMPLATE_DIR}/empty.h.template" PARENT_SCOPE)
  elseif("${FILE_EXTENSION}" STREQUAL ".cpp")
    set(${OUTPUT_VARIABLE} "${BIELD_FILE_TEMPLATE_DIR}/empty.cpp.template" PARENT_SCOPE)
  elseif("${FILE_EXTENSION}" STREQUAL ".inl")
    set(${OUTPUT_VARIABLE} "${BIELD_FILE_TEMPLATE_DIR}/empty.inl.template" PARENT_SCOPE)
  endif()
endfunction(bield_get_file_template)

function(bield_create_missing_files)
  bield_indent_log_prefix("(creating missing files)")
  foreach(SRC_FILE ${ARGN})
    set(SRC_FILE "${CMAKE_CURRENT_LIST_DIR}/${SRC_FILE}")
    if(NOT EXISTS "${SRC_FILE}")
      get_filename_component(SRC_FILE_EXT "${SRC_FILE}" EXT)
      bield_get_file_template("${SRC_FILE_EXT}" SRC_TEMPLATE)
      bield_log(3 "using template: ${SRC_TEMPLATE}")
      file(READ "${SRC_TEMPLATE}" SRC_TEMPLATE)
      file(WRITE "${SRC_FILE}" "${SRC_TEMPLATE}")
      bield_log(1 "generated: ${SRC_FILE}")
    endif()
  endforeach()
endfunction(bield_create_missing_files)

# project
################################################################################

# signature:
# bield_project(TheProjectName                        # the name of the project.
#            EXECUTABLE|(LIBRARY SHARED|STATIC)    # marks this project as either an executable or a library.
#            [PCH ThePchFileName]                  # the name of the precompiled-header file;
#                                                  # if given, the project will be set up to use a precompiled header.
#            FILES file0 file1 ... fileN           # all files to include as sources.
#            [PACKAGES (SFML ...)|(ezEngine ...)] # the names and components of the packages this project depends on.
function(bield_project        PROJECT_NAME)
  set(bool_options         EXECUTABLE)
  set(single_value_options LIBRARY
                           PCH)
  set(multi_value_options  FILES
                           PACKAGES)
  bield_indent_log_prefix("{${PROJECT_NAME}}")
  bield_log(2 "parsing arguments")
  cmake_parse_arguments(PROJECT "${bool_options}" "${single_value_options}" "${multi_value_options}" ${ARGN})

  # error checking
  if(LIB_UNPARSED_ARGUMENTS)
    bield_warning_unparsed_args("unparsed args: ${LIB_UNPARSED_ARGUMENTS}")
  endif()

  if(PROJECT_EXECUTABLE AND PROJECT_LIBRARY)
    bield_error("you must either specify 'EXECUTABLE' or 'LIBRARY <value>' for a bield_project, not both.")
  elseif(NOT PROJECT_EXECUTABLE AND NOT PROJECT_LIBRARY)
    bield_error("either the 'EXECUTABLE' or the 'LIBRARY <value>' must be given to a bield_project.")
  endif()

  if(NOT PROJECT_FILES)
    bield_error("No files specified for project: ${PROJECT_NAME}")
  endif()

  if(BIELD_CREATE_MISSING_FILES)
    bield_create_missing_files(${PROJECT_FILES})
  endif()

  # actually start using the given data
  if(PROJECT_LIBRARY) # this project is a library
    bield_log(1 "project is a library (${PROJECT_LIBRARY})")
    add_library(${PROJECT_NAME} ${PROJECT_LIBRARY} ${PROJECT_FILES})
  elseif(PROJECT_EXECUTABLE)
    bield_log(1 "project is an executable")
    add_executable(${PROJECT_NAME} ${PROJECT_FILES})
  endif()

  if(PROJECT_PCH)
    if(MSVC)
      bield_msvc_add_pch_flags("${PROJECT_PCH}" ${PROJECT_FILES} PREFIX "${PROJECT_NAME}")
    endif()
  endif(PROJECT_PCH)

  bield_group_sources_by_file_system(${PROJECT_FILES})

  bield_add_packages("${PROJECT_NAME}" ${PROJECT_PACKAGES})

  # add compiler flags
  if (BIELD_COMPILER_SETTINGS_ALL)
    bield_log(2 "setting compiler flags: ${BIELD_COMPILER_SETTINGS_ALL}")
    set_target_properties (${PROJECT_NAME} PROPERTIES COMPILE_FLAGS ${BIELD_COMPILER_SETTINGS_ALL})
  endif ()

  # add linker flags
  if (BIELD_LINKER_SETTINGS_ALL)
    bield_log(2 "setting linker flags (all): ${BIELD_LINKER_SETTINGS_ALL}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_DEBUG          ${BIELD_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELWITHDEBINFO ${BIELD_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE        ${BIELD_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_MINSIZEREL     ${BIELD_LINKER_SETTINGS_ALL})
  endif ()
  if (BIELD_LINKER_SETTINGS_DEBUG)
    bield_log(2 "setting linker flags (debug): ${BIELD_LINKER_SETTINGS_DEBUG}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_DEBUG          ${BIELD_LINKER_SETTINGS_DEBUG})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELWITHDEBINFO ${BIELD_LINKER_SETTINGS_DEBUG})
  endif ()
  if (BIELD_LINKER_SETTINGS_RELEASE)
    bield_log(2 "setting linker flags (release): ${BIELD_LINKER_SETTINGS_RELEASE}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE    ${BIELD_LINKER_SETTINGS_RELEASE})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_MINSIZEREL ${BIELD_LINKER_SETTINGS_RELEASE})
  endif ()
endfunction(bield_project)
