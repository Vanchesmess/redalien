
ARCHS = arm64
TARGET := iphone:clang:12.4:12.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RedAlien

RedAlien_FILES = \
    Tweak.x \
    Auth.m \
    RAProtocol.m \
    Video.m \
    SubIcon.m \
    Gallery.m \
    HTTPServer.m \
    LoginVC.m \
    JSONKit.m \
    MockResponse.m \
    FFmpeg.m \
    VideoPlayer.m

RedAlien_FRAMEWORKS = UIKit MediaPlayer

RedAlien_CFLAGS = \
    -std=gnu99 \
    -D_DARWIN_C_SOURCE \
    -D_GNU_SOURCE \
    -Wno-ignored-attributes \
    -w \
    -fno-exceptions \
    -fno-rtti \
    -Wno-ignored-optimization-argument \
    -Wno-unknown-argument

RedAlien_CXXFLAGS = $(RedAlien_CFLAGS)

RedAlien_LDFLAGS = -lSystem

include $(THEOS_MAKE_PATH)/tweak.mk

THEOS_DEVICE_PORT ?= 22

.PHONY: after-install
