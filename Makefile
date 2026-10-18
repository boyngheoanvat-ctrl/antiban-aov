# language: Makefile, file: makefile
THEOS ?= /opt/theos
include $(THEOS)/makefiles/common.mk

TARGET := iphone:clang:latest:14.0
ARCHS := arm64

LIBRARY_NAME := antiban-eri

antiban-eri_FILES := anticheat.mm
antiban-eri_CFLAGS := -fobjc-arc
antiban-eri_LDFLAGS := -F./

include $(THEOS)/makefiles/library.mk
