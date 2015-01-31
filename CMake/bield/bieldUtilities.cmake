
# Include guard.
if(BIELD_UTILITIES_INCLUDED)
  return()
endif()
set(BIELD_UTILITIES_INCLUDED ON)

### Dependencies
################################################################################

# For bield_process_pch
include(bield/bieldPCH)

# helper functions
################################################################################

function(bield_group_sources_by_file_system)
  bield_indent_log_prefix("(source grouping)")
  foreach(SRC_FILE ${ARGN})
    get_filename_component(SRC_DIR "${SRC_FILE}" DIRECTORY)
    string(REPLACE "/" "\\" SRC_DIR "${SRC_DIR}")
    source_group("${SRC_DIR}" FILES "${SRC_FILE}")
    bield_log(3 "${SRC_DIR} => ${SRC_FILE}")
  endforeach()
endfunction(bield_group_sources_by_file_system)

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

function(bield_create_all_missing_files)
  bield_indent_log_prefix("(creating missing files)")
  foreach(SRC_FILE ${ARGN})
    set(SRC_FILE "${CMAKE_CURRENT_LIST_DIR}/${SRC_FILE}")
    if(NOT EXISTS "${SRC_FILE}")
      get_filename_component(SRC_FILE_EXT "${SRC_FILE}" EXT)
      bield_get_file_template("${SRC_FILE_EXT}" SRC_TEMPLATE)
      if(EXISTS "${SRC_TEMPLATE}")
        bield_log(3 "using template: ${SRC_TEMPLATE}")
        file(READ "${SRC_TEMPLATE}" SRC_TEMPLATE)
      else()
        bield_log(3 "template not found: ${SRC_TEMPLATE}")
        set(SRC_TEMPLATE "")
      endif()
      file(WRITE "${SRC_FILE}" "${SRC_TEMPLATE}")
      bield_log(1 "generated: ${SRC_FILE}")
    endif()
  endforeach()
endfunction(bield_create_all_missing_files)

# project
################################################################################

# Needed for bield_apply_target_flags.
include(bield/bieldFlags)

# signature:
# bield_project(TheProjectName                        # the name of the project.
#               EXECUTABLE|(LIBRARY SHARED|STATIC)    # marks this project as either an executable or a library.
#               [PCH PCH.H PCH.cpp]                   # the name of the precompiled-header files;
#                                                     # if given, the project will be set up to use a precompiled header.
#               FILES file0 file1 ... fileN)          # all files to include as sources.
function(bield_project     PROJECT_NAME)
  set(bool_options         EXECUTABLE)
  set(single_value_options LIBRARY)
  set(multi_value_options  FILES
                           PCH)
  bield_indent_log_prefix("{${PROJECT_NAME}}")
  bield_log(2 "parsing arguments")
  cmake_parse_arguments(PROJECT "${bool_options}" "${single_value_options}" "${multi_value_options}" ${ARGN})

  ### Error checking.
  ##############################################################################
  if(PROJECT_UNPARSED_ARGUMENTS)
    bield_warning_unparsed_args("unparsed args: ${PROJECT_UNPARSED_ARGUMENTS}")
  endif()

  if(PROJECT_EXECUTABLE AND PROJECT_LIBRARY)
    bield_error("you must either specify 'EXECUTABLE' or 'LIBRARY <value>' for a bield_project, not both.")
  elseif(NOT PROJECT_EXECUTABLE AND NOT PROJECT_LIBRARY)
    bield_error("either the 'EXECUTABLE' or the 'LIBRARY <value>' must be given to a bield_project.")
  endif()

  list(APPEND PROJECT_FILES ${PROJECT_PCH})
  if(NOT PROJECT_FILES)
    bield_error("No files specified for project: ${PROJECT_NAME}")
  endif()

  list(REMOVE_DUPLICATES PROJECT_FILES)
  if(BIELD_CREATE_MISSING_FILES)
    bield_create_all_missing_files(${PROJECT_FILES})
  endif()

  ### Create the target
  ##############################################################################
  if(PROJECT_LIBRARY)
    add_library(${PROJECT_NAME} ${PROJECT_LIBRARY} ${PROJECT_FILES})
    if(PROJECT_LIBRARY STREQUAL "SHARED")
      string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPERCASE)
      # For a project name HelloWorld => HELLOWORLD_EXPORTS
      set_target_properties(${PROJECT_NAME} PROPERTIES
                            DEFINE_SYMBOL ${PROJECT_NAME_UPPERCASE}_EXPORTS)
    endif()
  elseif(PROJECT_EXECUTABLE)
    add_executable(${PROJECT_NAME} ${PROJECT_FILES})
  else()
    bield_error("This should be unreachable code!")
  endif()

  bield_apply_linker_flags(${PROJECT_NAME})
  bield_group_sources_by_file_system(${PROJECT_FILES})
  if(BIELD_USE_PCH)
    # Process pch files, adding flags to all other sources.
    bield_process_pch(${PROJECT_NAME} ${PROJECT_PCH} ${PROJECT_FILES})
  endif()
endfunction(bield_project)
