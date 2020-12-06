cmake_minimum_required(VERSION 3.12...3.19)

project(PreCommitTest VERSION "1.0" DESCRIPTION "CMake module to install pre-commit" HOMEPAGE_URL "https://github.com/flagarde/PreCommit" LANGUAGES NONE)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}")

include(PreCommit)

add_subdirectory(tests)
