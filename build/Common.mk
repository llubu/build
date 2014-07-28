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

GLOBAL_CFLAGS_COMMON := -fPIE -fstrict-aliasing -fstack-protector-all -fstrict-overflow
GLOBAL_debug_CFLAGS := -Wall -Wextra -g -O0 -fno-omit-frame-pointer
GLOBAL_release_CFLAGS := -Wall -Wextra -O4 -fomit-frame-pointer
GLOBAL_CFLAGS := $(GLOBAL_CFLAGS_COMMON) $(GLOBAL_$(CONFIG)_CFLAGS)

GLOBAL_CFLAGS_LIB :=
GLOBAL_CFLAGS_ARC :=
GLOBAL_CFLAGS_EXE :=

GLOBAL_LDFLAGS_COMMON := -Wl,-rpath,\$$$$ORIGIN -pie
GLOBAL_debug_LDFLAGS :=
GLOBAL_release_LDFLAGS :=
GLOBAL_LDFLAGS := $(GLOBAL_LDFLAGS_COMMON) $(GLOBAL_$(CONFIG)_LDFLAGS)

GLOBAL_LDFLAGS_LIB := -shared -fvisibility=hidden
GLOBAL_LDFLAGS_ARC := -static
GLOBAL_LDFLAGS_EXE :=

FINAL_OUT_DIR := $(CONFIG)-$(ARCH)

define CREATE_MODULE
$(1)_CONFIG_DIR := $(1)/$(CONFIG)-$(ARCH)
$(1)_OBJ_DIR := $$($(1)_CONFIG_DIR)/obj
$(1)_OBJECTS := $(addprefix $$($(1)_OBJ_DIR)/,$$($(1)_SOURCES:%c=%o))
$(1)_BINARY := $(addprefix $$($(1)_CONFIG_DIR)/,$(1))

$(1)_FINAL_CFLAGS := $$($(1)_CFLAGS) $(GLOBAL_CFLAGS) $(GLOBAL_CFLAGS_$(2))
$(1)_FINAL_LDFLAGS := $$($(1)_LDFLAGS) $(GLOBAL_LDFLAGS) $(GLOBAL_LDFLAGS_$(2))

$(1)_COPY: $$($(1)_BINARY)
	@echo "Copying " $$($(1)_BINARY) $(FINAL_OUT_DIR)
	mkdir -p $(FINAL_OUT_DIR)
	cp $$($(1)_BINARY) $(FINAL_OUT_DIR)/$(1)

$$($(1)_BINARY): $$($(1)_OBJECTS)
	mkdir -p $$($(1)_OBJ_DIR)
	$(CC) $$($(1)_FINAL_LDFLAGS) -o $$@ $$($(1)_OBJECTS) $(LIBS)

$$($(1)_OBJECTS): $(addprefix $(1)/,$($(1)_SOURCES))
	@echo Compiling $($(1)_SOURCES) $(GLOBAL_CFLAGS)
	$(CC) $$($(1)_FINAL_CFLAGS) -c $$< -o $$@

$(1)_CLEAN:
	rm -f $$($(1)_OBJECTS)
	rm -f $$($(1)_BINARY)
	rm -f $(FINAL_OUT_DIR)/$(1)

MODULES += $(1)_COPY
MODULES_CLEAN += $(1)_CLEAN
endef # CREATE_MODULE

include $(addsuffix /Module.mk,$(PROJECTS))

.PHONY: all
all: $(MODULES)
	@echo Making $(MODULES)

.PHONY: clean
clean: $(MODULES_CLEAN)
	@echo Cleaning $(MODULES_CLEAN)


