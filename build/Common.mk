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
$(error "Building " $(CONFIG))
endif

ARCH_UNAME = $(shell uname -m)
ifeq ($(ARCH_UNAME),x86_64)
	ARCH := x86_64
else
	ARCH := x86
endif # $(ARCH_UNAME)

define CREATE_MODULE
$(1)_OBJECTS := $(addprefix $(1)/obj/,$$($(1)_SOURCES:%c=%o))
$(1)_BINARY := $(addprefix $(1)/$(CONFIG)-$(ARCH)/,$(1))
$$($(1)_BINARY): $$($(1)_OBJECTS)

$$($(1)_OBJECTS): $(addprefix $(1)/,$($(1)_SOURCES))

MODULES += $$($(1)_BINARY)

endef # CREATE_MODULE

include $(addsuffix /Module.mk,$(PROJECTS))

$(warning MODULES: $(MODULES))

.PHONY: all
all: $(MODULES)

