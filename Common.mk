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

CONFIGURATIONS = release debug coverage
ifeq ($(findstring $(CONFIG),$(CONFIGURATIONS)),)
$(error Error building $(CONFIG))
endif

ifeq ($(shell uname -s),Linux)
	PLATFORM := linux
else
	ifeq ($(shell uname -s),Windows_NT)
		PLATFORM := windows
	else
		ifeq ($(shell uname -s),Darwin)
			PLATFORM := mac
		endif
	endif
endif # PLATFORM

ARCH_UNAME = $(shell uname -m)
ifeq ($(ARCH_UNAME),x86_64)
	ARCH := x86_64
else
	ARCH := x86
endif # $(ARCH_UNAME)

UNIQUE = $(if $(1),$(firstword $(1)) $(call UNIQUE,$(filter-out $(firstword $(1)),$(1))))

ifeq ($(SANITIZE),thread)
	CFLAGS += -fsanitize=thread
	CXXFLAGS += -fsanitize=thread
	LDFLAGS += -fsanitize=thread -ltsan
else
ifeq ($(findstring address,$(SANITIZE)),address)
	CFLAGS += -fsanitize=address
	CXXFLAGS += -fsanitize=address
	LDFLAGS += -fsanitize=address
	LDFLAGS += -lasan
endif # address
ifeq ($(findstring undefined,$(SANITIZE)),undefined)
	CFLAGS += -fsanitize=undefined -fno-sanitize-recover
	CXXFLAGS += -fsanitize=undefined -fno-sanitize-recover
	LDFLAGS += -fsanitize=undefined -lubsan
else ifeq ($(SANITIZE)),memory)
	CFLAGS += -fsanitize=memory
	CXXFLAGS += -fsanitize=memory
	LDFLAGS += -fsanitize=memory
endif # undefined
endif # thread


GLOBAL_CFLAGS_COMMON := $(CFLAGS) -fstrict-aliasing -fstack-protector -fstrict-overflow
GLOBAL_coverage_CFLAGS := -Wall -Wextra -Wshadow -Wmissing-prototypes -Wstrict-prototypes -O0 -fprofile-arcs -ftest-coverage
GLOBAL_debug_CFLAGS := -Wall -Wextra -Wshadow -Wmissing-prototypes -Wstrict-prototypes -g -O0 -fno-omit-frame-pointer
GLOBAL_release_CFLAGS := -Wall -Wextra -Wshadow -Wmissing-prototypes -Wstrict-prototypes -O3 -fomit-frame-pointer
GLOBAL_CFLAGS := $(GLOBAL_CFLAGS_COMMON) $(GLOBAL_$(CONFIG)_CFLAGS)

GLOBAL_CXXFLAGS_COMMON := $(CXXFLAGS) -fstrict-aliasing -fstack-protector -fstrict-overflow
GLOBAL_coverage_CXXFLAGS := -Wall -Wextra -Wshadow -O0 -fprofile-arcs -ftest-coverage
GLOBAL_debug_CXXFLAGS := -Wall -Wextra -Wshadow -g -O0 -fno-omit-frame-pointer
GLOBAL_release_CXXFLAGS := -Wall -Wextra -Wshadow -O3 -fomit-frame-pointer
GLOBAL_CXXFLAGS := $(GLOBAL_CXXFLAGS_COMMON) $(GLOBAL_$(CONFIG)_CXXFLAGS)

GLOBAL_CFLAGS_LIB := -fPIC -fvisibility=hidden
GLOBAL_CFLAGS_ARC := -fPIC
GLOBAL_CFLAGS_EXE := -fPIE

GLOBAL_LDFLAGS_COMMON := $(LDFLAGS)
GLOBAL_coverage_LDFLAGS :=
GLOBAL_debug_LDFLAGS :=
GLOBAL_release_LDFLAGS :=
GLOBAL_LDFLAGS := $(GLOBAL_LDFLAGS_COMMON) $(GLOBAL_$(CONFIG)_LDFLAGS)

ifeq ($(PLATFORM),linux)
	GLOBAL_LDFLAGS_LIB := -shared
else
	ifeq ($(PLATFORM),mac)
		GLOBAL_LDFLAGS_LIB := -dynamiclib
	endif # Mac
endif # Linux

GLOBAL_LDFLAGS_LIB += -Wl,-rpath,\$$$$$$$$ORIGIN
GLOBAL_LDFLAGS_ARC := -r -c
GLOBAL_LDFLAGS_EXE := -Wl,-rpath,\$$$$$$$$ORIGIN -pie

ifeq ($(PLATFORM),linux)
	LIB_SUFFIX := .so
else
	ifeq ($(PLATFORM),mac)
		LIB_SUFFIX := .dylib
	endif # Mac
endif # Linux

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
ifeq ($(CONFIG),coverage)
	$(1)_LIBS += -lgcov
endif
endef # CREATE_RECURSIVE_DEPENDS

define CREATE_MODULE_VARIABLES
$(1)_DEPENDS_LIBS := $(foreach LIB,$($(1)_DEPENDS_LIB_RULES),$($(LIB)))
$(1)_LIBS += $$($(1)_DEPENDS_LIBS)
$(1)_DEPENDS_HEADERS := $(foreach HEADER_RULE,$($(1)_DEPENDS) $($(1)_DEPENDS_INCLUDE),$(foreach HEADER,$($(HEADER_RULE)_HEADERS),$($(HEADER_RULE)_DIR)/$(HEADER)))
endef # CREATE_MODULE_VARIABLES

define COPY_FILES
COPY_FILE_DIRS += $(INSTALL_PATH)/$(1)
FILES_TO_COPY += $(foreach CP_FILE,$($(1)_FILES_TO_COPY),$(addprefix $(1)/,$(CP_FILE)))
endef  # COPY_FILES

define CREATE_MODULE
$(1)_TYPE := $(2)
$(1)_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
$(1)_CONFIG_DIR := $$($(1)_DIR)$(CONFIG)-$(ARCH)
$(1)_OBJ_DIR := $$($(1)_CONFIG_DIR)/obj
$(1)_OBJ_FILES := $$(addsuffix .o,$$(basename $$(notdir $$($(1)_SOURCES))))
$(1)_OBJECTS := $$(addprefix $$($(1)_OBJ_DIR)/,$$($(1)_OBJ_FILES))
$(1)_COV_FILES := $$(addsuffix .gcno,$$(basename $$(notdir $$($(1)_SOURCES))))
$(1)_COVERAGE := $$(addprefix $$($(1)_OBJ_DIR)/,$$($(1)_COV_FILES))
$(1)_BINARY_FILENAME := $(addsuffix $$($(2)_SUFFIX),$(1))
$(1)_BINARY := $(addprefix $$($(1)_CONFIG_DIR)/,$$($(1)_BINARY_FILENAME))
$(1)_COPY := $(FINAL_OUT_DIR)/$$($(1)_BINARY_FILENAME)

$(1)_DEPENDS_LIB_RULES := $(addsuffix _COPY,$($(1)_DEPENDS)) $(addsuffix _COPY,$($(1)_DEPENDS_LINK))
$(1)_HEADER_DIRS += $$($(1)_DIR) $(foreach HEADER_DIR_PROJ,$($(1)_DEPENDS) $($(1)_DEPENDS_INCLUDE),$$($(HEADER_DIR_PROJ)_DIR))

$(1)_FINAL_CFLAGS := $(GLOBAL_CFLAGS) $(GLOBAL_CFLAGS_$(2)) $$($(1)_CFLAGS)
$(1)_FINAL_CXXFLAGS := $(GLOBAL_CXXFLAGS) $(GLOBAL_CFLAGS_$(2)) $$($(1)_CXXFLAGS)

# since ar can have ONLY ONE operation to execute on GNU ar
ifeq ($(2),ARC)
$(1)_FINAL_LDFLAGS := $(GLOBAL_LDFLAGS_$(2))
else
$(1)_FINAL_LDFLAGS := $(GLOBAL_LDFLAGS_$(2)) $(GLOBAL_LDFLAGS) $$($(1)_LDFLAGS)
endif

ifeq ($(2),LIB)
ifeq ($(PLATFORM),linux)
$(1)_FINAL_LDFLAGS += -Wl,-soname,$$($(1)_BINARY_FILENAME)
ifeq ($(SANITIZE),)
$(1)_FINAL_LDFLAGS += -Wl,--no-undefined
endif # SANITIZE
endif # Linux
endif # LIB

$$($(1)_COPY): $$($(1)_BINARY)
	cp $$($(1)_BINARY) $$($(1)_COPY)

define $(1)_CREATE_BINARY_RULES
$$(eval $(call $(1)_BINARY_RULES))
ifeq ($(2),$(filter EXE LIB,$(2)))
$$($(1)_BINARY): $$($(1)_OBJECTS) $$($(1)_DEPENDS_LIBS) | $(FINAL_OUT_DIR)
	$(CC) -o $$$$@ $$(strip $$($(1)_OBJECTS) $$($(1)_FINAL_LDFLAGS) $$(call UNIQUE,$$($(1)_LIBS)))
else ifeq ($(2),ARC)
$$($(1)_BINARY): $$($(1)_OBJECTS) $$($(1)_DEPENDS_LIBS) | $(FINAL_OUT_DIR)
	$(AR) $$(strip $$($(1)_FINAL_LDFLAGS) $$$$@ $$($(1)_OBJECTS))
endif # EXE

.PHONY: $(1)
$(1): $$($(1)_COPY)

$(1)_CLEAN:
	-rm -f $$($(1)_COVERAGE)
	-rm -f $$($(1)_OBJECTS)
	-rm -f $$($(1)_BINARY)
	-rm -f $(FINAL_OUT_DIR)/$$($(1)_BINARY_FILENAME)

$(1)_RUN: $$($(1)_COPY)
ifeq ($(2),EXE)
	$$($(1)_RUN_TEST_ENV) $$($(1)_COPY) $$($(1)_RUN_TEST_ARGS)
endif # EXE

endef # $(1)_CREATE_BINARY_RULES

$$($(1)_OBJ_DIR):
	mkdir -p $$($(1)_OBJ_DIR)

define $(1)_CREATE_SOURCE_RULES
ifeq ($(2),$(filter EXE LIB ARC,$(2)))
$$($(1)_OBJ_DIR)/$$(basename $$(notdir $$(1))).o: $$(abspath $$($(1)_DIR)$$(1)) $$($(1)_DEPENDS_HEADERS) \
	$$(addprefix $$(abspath $$($(1)_DIR))/,$$($(1)_HEADERS)) $(MAKEFILE_LIST) | $$($(1)_OBJ_DIR)
ifeq ($$(suffix $$(1)),.c)
	$(CC) -c $$$$< -o $$$$@ $$(strip $$($(1)_FINAL_CFLAGS) $$(call UNIQUE,$$(addprefix -I,$$($(1)_HEADER_DIRS))))
else ifneq ($$(filter $$(suffix $$(1)),.cc .cpp),)
	$(CXX) -c $$$$< -o $$$$@ $$(strip $$($(1)_FINAL_CXXFLAGS) $$(call UNIQUE,$$(addprefix -I,$$($(1)_HEADER_DIRS))))
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


.PHONY: install
install:
	mkdir -p $(INSTALL_PATH)/bin
	$(foreach MODULE,$(MODULES),install -p -m 755 $($(MODULE)_COPY) $(INSTALL_PATH)/bin/ ;)
	mkdir -p $(COPY_FILE_DIRS)
	$(foreach CP_FILE,$(FILES_TO_COPY),install -p -m 644 $(CP_FILE) $(INSTALL_PATH)/$(dir $(CP_FILE)) ;)

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

