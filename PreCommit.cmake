include_guard(GLOBAL)

if(NOT COMMAND colors)
  # Colorize
  macro(colors)
    if(NOT WIN32)
      if(${ARGV0} STREQUAL TRUE)
        string(ASCII 27 Esc)
        set(Reset "${Esc}[m")
        set(BoldRed "${Esc}[1;31m")
        set(BoldMagenta "${Esc}[1;35m")
        set(BoldYellow "${Esc}[1;33m")
        set(BoldGreen "${Esc}[1;32m")
      else()
        unset(Reset)
        unset(BoldRed)
        unset(BoldMagenta)
        unset(BoldYellow)
        unset(BoldGreen)
      endif()
    endif()
  endmacro()
endif()

colors(TRUE)

find_package(Python3 COMPONENTS Interpreter QUIET)
if(NOT ${Python3_FOUND})
  message("${BoldRed}!! Python3 not found. Aborting pre-commit downloading and using !!${Reset}")
  return()
endif()

if(NOT DEFINED PRECOMMIT_VERSION)
  set(PRECOMMIT_VERSION "2.9.0")
endif()

if(NOT DEFINED PRECOMMIT_INSTALL_PATH)
  set(PRECOMMIT_INSTALL_PATH "${CMAKE_BINARY_DIR}/pre-commit")
endif()

include(FindPackageHandleStandardArgs)
find_program(PRECOMMIT_EXECUTABLE NAMES "pre-commit" DOC "Path to pre-commit : A framework for managing and maintaining multi-language pre-commit hooks.")

if(NOT PRECOMMIT_SET STREQUAL "TRUE")
  if(NOT ${PRECOMMIT_EXECUTABLE} STREQUAL "PRECOMMIT_EXECUTABLE-NOTFOUND")
    execute_process(COMMAND "${PRECOMMIT_EXECUTABLE}" "--version" OUTPUT_VARIABLE RESULT)
    string(REGEX MATCH "[0-9]+.[0-9]+.[0-9]+" RESULT ${RESULT})
    if(NOT ${RESULT} STREQUAL ${PRECOMMIT_VERSION})
      set(PRECOMMIT_EXECUTABLE "PRECOMMIT_EXECUTABLE-NOTFOUND")
      message("${BoldYellow}## pre-commit version ${PRECOMMIT_VERSION} needed. Found version ${RESULT} ##${Reset}")
    else()
      set(PRECOMMIT_SET TRUE CACHE INTERNAL "pre-commit is set.")
    endif()
  endif()
endif()

if(${PRECOMMIT_EXECUTABLE} STREQUAL "PRECOMMIT_EXECUTABLE-NOTFOUND")
  set(PRECOMMIT_EXECUTABLE "${PRECOMMIT_INSTALL_PATH}/pre-commit-${PRECOMMIT_VERSION}.pyz")
  set(PRECOMMITSHA256_LOCATION "${PRECOMMIT_INSTALL_PATH}/pre-commit-${PRECOMMIT_VERSION}.pyz.sha256sum")

  # Download pre-commit
  macro(download_pre_commit)
    message("${BoldMagenta}-- Downloading pre-commit to ${PRECOMMIT_EXECUTABLE} --${Reset}")
    file(DOWNLOAD https://github.com/pre-commit/pre-commit/releases/download/v${PRECOMMIT_VERSION}/pre-commit-${PRECOMMIT_VERSION}.pyz ${PRECOMMIT_EXECUTABLE} SHOW_PROGRESS)
    # file(CHMOD ${PRECOMMIT_EXECUTABLE} FILE_PERMISSIONS WORLD_EXECUTE FILE_PERMISSIONS WORLD_READ FILE_PERMISSIONS WORLD_WRITE)
    file(SHA256 ${PRECOMMIT_EXECUTABLE} PRECOMMIT_SHA256)
  endmacro()

  # Download pre-commit SHA256
  macro(download_pre_commit_sha256)
    message("${BoldMagenta}-- Downloading pre-commit to ${PRECOMMITSHA256_LOCATION} --${Reset}")
    file(DOWNLOAD https://github.com/pre-commit/pre-commit/releases/download/v${PRECOMMIT_VERSION}/pre-commit-${PRECOMMIT_VERSION}.pyz.sha256sum ${PRECOMMITSHA256_LOCATION} SHOW_PROGRESS)
    # file(CHMOD ${PRECOMMITSHA256_LOCATION} FILE_PERMISSIONS WORLD_EXECUTE FILE_PERMISSIONS WORLD_READ FILE_PERMISSIONS WORLD_WRITE)
    file(STRINGS ${PRECOMMITSHA256_LOCATION} PRECOMMIT_SHA256_REAL LENGTH_MAXIMUM 64 LIMIT_COUNT 1)
  endmacro()

  if(NOT (EXISTS ${PRECOMMIT_EXECUTABLE}))
    download_pre_commit()
  endif()
  if(NOT (EXISTS ${PRECOMMITSHA256_LOCATION}))
    download_pre_commit_sha256()
  endif()

  while(NOT "${PRECOMMIT_SHA256_REAL}" STREQUAL "${PRECOMMIT_SHA256}")
    if(NOT (EXISTS ${PRECOMMIT_EXECUTABLE}))
      download_pre_commit()
    else()
      file(REMOVE ${PRECOMMIT_EXECUTABLE})
    endif()
    if(NOT (EXISTS ${PRECOMMITSHA256_LOCATION}))
      download_pre_commit_sha256()
    else()
      file(REMOVE ${PRECOMMITSHA256_LOCATION})
    endif()
  endwhile()
  set(PRECOMMIT_SET TRUE CACHE INTERNAL "pre-commit is set.")
endif()

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.git)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.pre-commit-config.yaml")
    # Configure the .pre-commit-config.yaml
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/.pre-commit-config.yaml" "${CMAKE_CURRENT_BINARY_DIR}/.pre-commit-config.yaml" )
    execute_process(COMMAND ${Python3_EXECUTABLE} "${PRECOMMIT_EXECUTABLE}" "install" "-c" "${CMAKE_CURRENT_BINARY_DIR}/.pre-commit-config.yaml" WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE RESULT)
    string(REGEX REPLACE "[\n\r\n]" "" RESULT ${RESULT})
    message("${BoldGreen}** ${RESULT} **${Reset}")
  else()
    message("${BoldYellow}## No .pre-commit-config.yaml in folder ${CMAKE_CURRENT_SOURCE_DIR} ##${Reset}")
    message("${BoldYellow}## Not setting pre-commit ##${Reset}")
  endif()
else()
  message("${BoldRed}!! ${CMAKE_CURRENT_SOURCE_DIR} doesn't contains .git folder !!${Reset}")
  message("${BoldRed}!! Not setting pre-commit !!${Reset}")
endif()

colors(FALSE)
