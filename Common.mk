# The MIT License (MIT)
#
# Copyright (c) 2014 Ryan Salsamendi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Default value
CONFIG := release

CONFIGURATIONS = release debug
ifeq ($$(findstring $$(CONFIG),$$(CONFIGURATIONS)),)
$(error Error building $(CONFIG))
else
$(warning Configuration: $(CONFIG))
endif

ARCH_UNAME = $(shell uname -m)
ifeq ($(ARCH_UNAME),x86_64)
	ARCH := x86_64
else
	ARCH := x86
endif # $(ARCH_UNAME)

GLOBAL_CFLAGS_COMMON := $(CFLAGS) -fstrict-aliasing -fstack-protector-all -fstrict-overflow
GLOBAL_debug_CFLAGS := -Wall -Wextra -g -O0 -fno-omit-frame-pointer
GLOBAL_release_CFLAGS := -Wall -Wextra -O4 -fomit-frame-pointer
GLOBAL_CFLAGS := $(GLOBAL_CFLAGS_COMMON) $(GLOBAL_$(CONFIG)_CFLAGS)

GLOBAL_CFLAGS_LIB := -fPIC -fvisibility=hidden
GLOBAL_CFLAGS_ARC := -fPIC
GLOBAL_CFLAGS_EXE := -fPIE

GLOBAL_LDFLAGS_COMMON := $(LDFLAGS)
GLOBAL_debug_LDFLAGS :=
GLOBAL_release_LDFLAGS :=
GLOBAL_LDFLAGS := $(GLOBAL_LDFLAGS_COMMON) $(GLOBAL_$(CONFIG)_LDFLAGS)

GLOBAL_LDFLAGS_LIB := -shared -Wl,-rpath,\$$$$$$$$ORIGIN
GLOBAL_LDFLAGS_ARC := -r -c
GLOBAL_LDFLAGS_EXE := -Wl,-rpath,\$$$$$$$$ORIGIN -pie

LIB_SUFFIX := .so
ARC_SUFFIX := .a
EXE_SUFFIX :=
DRV_SUFFIX := .ko

FINAL_OUT_DIR := $(CONFIG)-$(ARCH)

$(FINAL_OUT_DIR):
	mkdir -p $(FINAL_OUT_DIR)

define CREATE_RECURSIVE_DEPENDS
$(1)_DEPENDS_LIBS += $(foreach LIB,$$($(1)_DEPENDS),$($($(LIB)_DEPENDS_LIBS)))
$(1)_DEPENDS_LIBS += $(foreach LIB,$$($(1)_DEPENDS_LINK),$($($(LIB)_DEPENDS_LIBS)))
$(1)_DEPENDS_LIBS := $(sort $$($(1)_DEPENDS_LIBS))

$(1)_LIBS += $(foreach LIB,$($(1)_DEPENDS),$($(LIB)_LIBS))
$(1)_LIBS += $(foreach LIB,$($(1)_DEPENDS_LINK),$($(LIB)_LIBS))
$(1)_LIBS := $(sort $$($(1)_LIBS))
endef # CREATE_RECURSIVE_DEPENDS

define CREATE_MODULE_VARIABLES
$(1)_DEPENDS_LIBS := $(foreach LIB,$($(1)_DEPENDS_LIB_RULES),$($(LIB)))
$(1)_LIBS += $$($(1)_DEPENDS_LIBS)
$(1)_DEPENDS_HEADERS := $(foreach HEADER_RULE,$($(1)_DEPENDS),$(foreach HEADER,$($(HEADER_RULE)_HEADERS),$($(HEADER_RULE)_DIR)/$(HEADER)))
endef # CREATE_MODULE_VARIABLES

define CREATE_MODULE
$(1)_TYPE := $(2)
$(1)_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
$(1)_CONFIG_DIR := $$($(1)_DIR)$(CONFIG)-$(ARCH)
$(1)_OBJ_DIR := $$($(1)_CONFIG_DIR)/obj
$(1)_OBJ_FILES := $$(addsuffix .o,$$(basename $$(notdir $$($(1)_SOURCES))))
$(1)_OBJECTS := $$(addprefix $$($(1)_OBJ_DIR)/,$$($(1)_OBJ_FILES))
$(1)_BINARY_FILENAME := $(addsuffix $$($(2)_SUFFIX),$(1))
$(1)_BINARY := $(addprefix $$($(1)_CONFIG_DIR)/,$$($(1)_BINARY_FILENAME))
$(1)_COPY := $(FINAL_OUT_DIR)/$$($(1)_BINARY_FILENAME)

$(1)_DEPENDS_LIB_RULES := $(addsuffix _COPY,$($(1)_DEPENDS)) $(addsuffix _COPY,$($(1)_DEPENDS_LINK))
$(1)_HEADER_DIRS += $$($(1)_DIR) $(foreach HEADER_DIR_PROJ,$($(1)_DEPENDS) $($(1)_DEPENDS_INCLUDE),$$($(HEADER_DIR_PROJ)_DIR))

$(1)_FINAL_CFLAGS := $(GLOBAL_CFLAGS) $(GLOBAL_CFLAGS_$(2)) $$($(1)_CFLAGS)
$(1)_FINAL_LDFLAGS := $(GLOBAL_LDFLAGS) $(GLOBAL_LDFLAGS_$(2)) $$($(1)_LDFLAGS)

ifeq ($(2),LIB)
$(1)_FINAL_LDFLAGS += -Wl,-soname,$$($(1)_BINARY_FILENAME)
endif # LIB

$$($(1)_COPY): $$($(1)_BINARY)
	cp $$($(1)_BINARY) $$($(1)_COPY)

define $(1)_CREATE_BINARY_RULES
$$(eval $(call $(1)_BINARY_RULES))
ifeq ($(2),$(filter EXE LIB,$(2)))
$$($(1)_BINARY): $$($(1)_OBJECTS) $$($(1)_DEPENDS_LIBS) | $(FINAL_OUT_DIR)
	$(CC) $$($(1)_FINAL_LDFLAGS) -o $$$$@ $$($(1)_OBJECTS) $$($(1)_LIBS)
else ifeq ($(2),ARC)
$$($(1)_BINARY): $$($(1)_OBJECTS) | $(FINAL_OUT_DIR)
	$(AR) $$($(1)_FINAL_LDFLAGS) $$$$@ $$($(1)_OBJECTS)
endif # EXE

.PHONY: $(1)
$(1): $$($(1)_COPY)

$(1)_CLEAN:
	-rm -f $$($(1)_OBJECTS)
	-rm -f $$($(1)_BINARY)
	-rm -f $(FINAL_OUT_DIR)/$$($(1)_BINARY_FILENAME)

$(1)_RUN: $$($(1)_COPY)
ifeq ($(2),EXE)
	$$($(1)_COPY)
endif # EXE

endef # $(1)_CREATE_BINARY_RULES

$$($(1)_OBJ_DIR):
	mkdir -p $$($(1)_OBJ_DIR)

define $(1)_CREATE_SOURCE_RULES
ifeq ($(2),$(filter EXE LIB ARC,$(2)))
$$($(1)_OBJ_DIR)/$$(basename $$(notdir $$(1))).o: $$(abspath $$($(1)_DIR)$$(1)) $$($(1)_DEPENDS_HEADERS) \
	$$(addprefix $$(abspath $$($(1)_DIR))/, $$($(1)_HEADERS)) $(MAKEFILE_LIST) | $$($(1)_OBJ_DIR)
ifeq ($$(suffix $$(1)),.c)
	$(CC) -c $$$$< -o $$$$@ $$($(1)_FINAL_CFLAGS) $$(addprefix -I,$$($(1)_HEADER_DIRS))
else ifneq ($$(filter $$(suffix $$(1)),.cc .cpp),)
	$(CXX) -c $$$$< -o $$$$@ $$($(1)_FINAL_CFLAGS) $$(addprefix -I,$$($(1)_HEADER_DIRS))
endif # .c
endif # EXE LIB ARC
endef # CREATE_SOURCE_RULES

MODULES += $(1)
MODULES_CLEAN += $(1)_CLEAN

ifneq ($(filter $(MAKECMDGOALS),test clean-test run-test),)
ifeq ($(TESTS_READY),1)
TEST_MODULES += $(1)
TEST_MODULES_CLEAN += $(1)_CLEAN
TEST_MODULES_RUN += $(1)_RUN
endif # TESTS_READY

endif # MAKECMDGOALS
endef # CREATE_MODULE

include $(addsuffix /Module.mk,$(PROJECTS))

ifneq ($(filter $(MAKECMDGOALS),test clean clean-test run-test),)
TESTS_READY := 1
include $(addsuffix /Module.mk,$(TEST_PROJECTS))
endif # MAKECMDGOALS,test

$(foreach MODULE,$(MODULES),$(eval $(call CREATE_MODULE_VARIABLES,$(MODULE))))
$(foreach MODULE,$(MODULES),$(eval $(call CREATE_RECURSIVE_DEPENDS,$(MODULE))))
$(foreach MODULE,$(MODULES),$(eval $(call $(MODULE)_CREATE_BINARY_RULES,$(MODULE))))
$(foreach MODULE,$(MODULES),$(foreach SOURCE,$($(MODULE)_SOURCES),$(eval $(call $(MODULE)_CREATE_SOURCE_RULES,$(SOURCE)))))

.PHONY: test
test: $(MODULES)

.PHONY: clean-test
clean-test: $(TEST_MODULES_CLEAN)

.PHONY: run-test
run-test: $(TEST_MODULES_RUN)

.PHONY: all
all: $(MODULES)

.PHONY: clean
clean: $(MODULES_CLEAN)

.DEFAULT_GOAL := all

