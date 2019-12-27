cmake_minimum_required(VERSION 3.5)

## Project name: ##
project(cynth CXX)

## C++ Standard: ##
set(CMAKE_CXX_STANDARD 17)

## Warnings: ##
set(CMAKE_CXX_FLAGS "-Wall")

## Output: ##
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)

## Include: ##
#  Local:
include_directories(${PROJECT_SOURCE_DIR}/inc)
#  ASIO - audio API
include_directories(${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/common)
include_directories(${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/host)
include_directories(${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/host/pc)
#  gcem - compile-time math library
include_directories(${PROJECT_SOURCE_DIR}/ext/gcem/include)

## Sources: ##
set(SOURCES
    ${PROJECT_SOURCE_DIR}/src/entry.cpp
    ${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/common/asio.cpp
    ${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/host/asiodrivers.cpp
    ${PROJECT_SOURCE_DIR}/ext/ASIOSDK2.3.2/host/pc/asiolist.cpp)

## Windows libraries: ##
ADD_LIBRARY(WINLIBS ${SOURCES})
target_link_libraries(WINLIBS -luuid)
target_link_libraries(WINLIBS -lksuser)
target_link_libraries(WINLIBS -lole32)
target_link_libraries(WINLIBS -lwinmm)

add_executable(cynth ${SOURCES})

target_link_libraries(cynth WINLIBS)