#!cmake

# \note Internal function. Do not use directly.
function(bield_process_pch PREFIX PCH_H PCH_CPP)
  if(MSVC)
    bield_msvc_add_pch_flags(${PREFIX} ${PCH_H} ${PCH_CPP} ${ARGN})
  #elseif() # TODO Precompiled headers on Linux/OSX?
  endif()
endfunction(bield_process_pch)

function(bield_msvc_add_pch_flags PREFIX PCH_H PCH_CPP)
  bield_indent_log_prefix("(pch)")

  set(PCH_CREATE_FLAG "/Yc${PREFIX}/${PCH_H}")
  set(PCH_USE_FLAG    "/Yu${PREFIX}/${PCH_H}")

  bield_log(3 "adding source property '${PCH_CREATE_FLAG}': ${PCH_CPP}")
  # add the necessary compiler flags to pch itself
  set_source_files_properties("${PCH_CPP}" PROPERTIES COMPILE_FLAGS "${PCH_CREATE_FLAG}")

  foreach(SRC_FILE ${ARGN})
    # we ignore the precompiled header and the corresponding .cpp file itself
    if(NOT SRC_FILE STREQUAL "${PCH_H}" AND NOT SRC_FILE STREQUAL "${PCH_CPP}")
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
