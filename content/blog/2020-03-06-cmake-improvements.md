---
author: Zack Galbreath
author-link: https://github.com/zackgalbreath
date: "2020-03-06T00:00:00Z"
published: true
title: Improvements to gRPC’s CMake Buildsystem
url: blog/cmake-improvements
---

For the past few months, [Kitware Inc.](https://www.kitware.com/) has been working with the gRPC team to improve gRPC’s CMake support. The goal of the effort was to modernize gRPC’s CMake build with the most current features and techniques CMake has to offer. This has improved the user experience for gRPC developers choosing to use gRPC’s CMake as a build system. During the effort the CMake build was looked at as a whole, and CMake related issues in GitHub were explored and resolved. A number of improvements were made that will give developers and end users a better experience when building gRPC with CMake.

One of the more exciting changes is the ability to seamlessly add gRPC to any CMake project and have all of its dependent libraries built using a simple CMake file. Prior to our recent changes this was a multi-step process. The user had to build and install each of gRPC’s dependencies separately, then build and install gRPC before finally building their own project. Now, this can all be done in one step. The following CMake code clones and builds the master branch of gRPC as documented [here](https://github.com/grpc/grpc/blob/master/src/cpp/README.md#cmake):

TODO: try rendering the latest release version on the page?

```
cmake_minimum_required(VERSION 3.15)
project(my_exe)

include(FetchContent)

FetchContent_Declare(
  gRPC
  GIT_REPOSITORY https://github.com/grpc/grpc
  GIT_TAG        master
  )
set(FETCHCONTENT_QUIET OFF)
FetchContent_MakeAvailable(gRPC)

add_executable(my_exe my_exe.cxx)
target_link_libraries(my_exe grpc++)
```

At configure time CMake uses git to clone the gRPC repository using the specified tag. Then gRPC will be added to the current CMake project via [add_subdirectory](https://cmake.org/cmake/help/latest/command/add_subdirectory.html) and built as part of the project. 

## What has changed?

We have addressed many of the CMake-related issues on GitHub, with bug fixes, documentation updates, and new features.

- We’ve improved the documentation for [building gRPC from source](https://github.com/grpc/grpc/blob/master/BUILDING.md) and [adding gRPC as a dependency to your CMake project](https://github.com/grpc/grpc/blob/master/src/cpp/README.md#cmake) giving developers several options for using gRPC from CMake from simply linking to a pre-built gRPC  to downloaded and building gRPC as part of the project.
- The CMake build now generates pkgconfig (*.pc) files in the installation directory, just like the Makefile build. This allows for pkgconfig to correctly find and report a CMake built version of gRPC
- If you are using CMake v3.13 or newer, you can now [build & install gRPC and its dependencies in a single step](https://github.com/grpc/grpc/blob/master/BUILDING.md#install-after-build), rather than building and installing each component separately.
- The CMake build now has configuration options to enable or disable building of every protoc plugin. For example, running CMake with `-DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF` will disable building the Python plugin. You can view and edit these options in cmake-gui (or ccmake) as you are configuring your build of gRPC.
- When building and installing gRPC as shared libraries, CMake now sets the .so version so the libraries are correctly versioned. (for example, libgrpc.so.9.0.0, libgrpc++.so.1.27.0-dev, etc).
- We’ve added examples showing how to [build gRPC using the CMake FetchContent module](https://github.com/grpc/grpc/blob/master/test/distrib/cpp/run_distrib_test_cmake_fetchcontent.sh), and how to [cross-compile gRPC for the Raspberry Pi](https://github.com/grpc/grpc/blob/master/test/distrib/cpp/run_distrib_test_raspberry_pi.sh).
- CMake can now find libc-ares even if c-ares has been built with Autotools instead of CMake. This allows gRPC to be built against the distribution-provided version of c-ares if it has been built with Autotools.
- If gRPC is built without testing enabled, the dependent testing frameworks will automatically be disabled, in order to avoid unnecessary compilation.
- Some issues with parallel builds have been addressed.

TODO(jtattermusch): add a note starting from what version are all the features available?

TODO(jtattermusch): add a note that we also removed the dependency on boringssl developer build
