# language: makefile, file: Makefile, target: iOS / Theos
TARGET := iphone:clang:latest:13.0
ARCHS = arm64 arm64e

TWEAK_NAME = Hacklag

AntiBanEri_FILES = Tweak.xm
AntiBanEri_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
