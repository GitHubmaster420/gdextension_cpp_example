#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# tweak this if you want to use different folders, or more folders, to store your source code in.
env.Append(CPPPATH=["src/"])

# --- Kinect SDK paths ---
kinect_sdk = r"C:\Program Files\Microsoft SDKs\Kinect\v2.0_1409"

env.Append(CPPPATH=[
    kinect_sdk + r"\inc"
])

env.Append(LIBPATH=[
    kinect_sdk + r"\Lib\x64"
])

env.Append(LIBS=[
    "Kinect20"
])

env.Append(CPPPATH = [ r"C:\vcpkg\packages\hidapi_x64-windows\include"])

env.Append(LIBPATH = [ r"C:\vcpkg\packages\hidapi_x64-windows\lib"])

env.Append(LIBS = [ "hidapi" ])

env.Append(LIBS=[
    "Ole32",
    "OleAut32",
    "Uuid"
])
sources = Glob("src/*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "demo/bin/libgdexample.{}.{}.framework/libgdexample.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "demo/bin/libgdexample.{}.{}.simulator.a".format(env["platform"], env["target"]),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "demo/bin/libgdexample.{}.{}.a".format(env["platform"], env["target"]),
            source=sources,
        )
else:
    library = env.SharedLibrary(
        "demo/bin/libgdexample{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )



Default(library)
