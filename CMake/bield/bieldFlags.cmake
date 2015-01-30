#!cmake

# \note Call this BEFORE the target is created.
function(bield_apply_compile_flags TARGET_NAME)
  message(">>> === Flags n stuff ========================================")
  # Flags for all configurations.
  set(${TARGET_NAME}_COMPILE_FLAGS "${BIELD_DEFAULT_COMPILE_FLAGS}" CACHE STRING
      "Compile flags for all configurations of ${TARGET_NAME}. Overrides CMAKE_CXX_FLAGS.")
  mark_as_advanced(${TARGET_NAME}_COMPILE_FLAGS)

  #set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_FLAGS "${${TARGET_NAME}_COMPILE_FLAGS}")
  set(CMAKE_CXX_FLAGS "${${TARGET_NAME}_COMPILE_FLAGS}" CACHE STRING "" FORCE)
  message(">>> CMAKE_CXX_FLAGS => ${CMAKE_CXX_FLAGS}")

  # Flags for specific configurations.
  foreach(cfg ${CMAKE_CONFIGURATION_TYPES}) # Debug, Release, ...
    string(TOUPPER ${cfg} CFG) # Debug => DEBUG
    set(${TARGET_NAME}_COMPILE_FLAGS_${CFG} "${BIELD_DEFAULT_COMPILE_FLAGS_${CFG}}" CACHE STRING
      "Compile flags for ${cfg} builds.")
    mark_as_advanced(${TARGET_NAME}_COMPILE_FLAGS_${CFG})
  set(CMAKE_CXX_FLAGS_${CFG} "${${TARGET_NAME}_COMPILE_FLAGS_${CFG}}"  CACHE STRING "" FORCE)
  message(">>> CMAKE_CXX_FLAGS_${CFG} => ${CMAKE_CXX_FLAGS_${CFG}}")
  endforeach()
endfunction(bield_apply_compile_flags)

# \note Call this AFTER the target is created.
function(bield_apply_link_flags TARGET_NAME)
  # Flags for all configurations.
  set(${TARGET_NAME}_LINK_FLAGS "${BIELD_DEFAULT_LINK_FLAGS}" CACHE STRING
      "Link flags for all configurations of ${TARGET_NAME}.")
  mark_as_advanced(${TARGET_NAME}_LINK_FLAGS)
  set_target_properties(${TARGET_NAME} PROPERTIES LINK_FLAGS "${${TARGET_NAME}_LINK_FLAGS}")

  # Flags for specific configurations.
  foreach(cfg ${CMAKE_CONFIGURATION_TYPES}) # Debug, Release, ...
    string(TOUPPER ${cfg} CFG) # Debug => DEBUG
    set(${TARGET_NAME}_LINK_FLAGS_${CFG} "${BIELD_DEFAULT_LINK_FLAGS_${CFG}}" CACHE STRING
      "Link flags for ${cfg} builds of ${TARGET_NAME}.")
    mark_as_advanced(${TARGET_NAME}_LINK_FLAGS_${CFG})
    set_target_properties(${TARGET_NAME} PROPERTIES LINK_FLAGS_${CFG} "${${TARGET_NAME}_LINK_FLAGS_${CFG}}")
  endforeach()
endfunction(bield_apply_link_flags)
