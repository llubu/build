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

