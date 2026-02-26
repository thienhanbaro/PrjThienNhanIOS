ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuangClient
QuangClient_FILES = api/LDVQuang.mm imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp imgui/backends/imgui_impl_metal.mm
QuangClient_CFLAGS = -fobjc-arc
QuangClient_CCFLAGS = -std=c++17
QuangClient_FRAMEWORKS = UIKit Metal MetalKit QuartzCore CoreGraphics
QuangClient_LIBRARIES = stdc++

include $(THEOS_MAKE_PATH)/tweak.mk
