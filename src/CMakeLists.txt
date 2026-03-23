# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_jasper_reports_library VERSION 0.0.1 LANGUAGES CXX)

find_package(JNI REQUIRED)

add_library(flutter_jasper_reports SHARED
  "jasper_bridge.cpp"
)

set_target_properties(flutter_jasper_reports PROPERTIES
  PUBLIC_HEADER flutter_jasper_reports.h
  OUTPUT_NAME "flutter_jasper_reports"
)

target_include_directories(flutter_jasper_reports PRIVATE ${JNI_INCLUDE_DIRS})
target_link_libraries(flutter_jasper_reports PRIVATE ${JNI_LIBRARIES})


target_compile_definitions(flutter_jasper_reports PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(flutter_jasper_reports PRIVATE "-Wl,-z,max-page-size=16384")
endif()
