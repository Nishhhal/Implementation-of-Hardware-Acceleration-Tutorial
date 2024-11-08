# Points to Utility Directory
COMMON_REPO = auxFiles
include $(COMMON_REPO)/utils.mk

# Run Target:
#   hw  - Compile for hardware
#   sw_emu/hw_emu - Compile for software/hardware emulation
# FPGA Board Platform (Default ~ xilinx_zcu104_base_202320_1)

SIZE := 14
TARGET := hw_emu
DEVICE := xilinx_zcu104_base_202320_1
LAB := pipeline
XCLBIN := ./xclbin

CXX := g++
VPP := $(XILINX_VITIS)/bin/v++

# Host source files
HOST_SRCS = src/$(LAB)_host.cpp

# Host compiler global settings
CXXFLAGS = -I$(XILINX_XRT)/include -I$(XILINX_HLS)/include -I$(XILINX_HLS)/include/etc -I/tools/Xilinx/Vitis_HLS/2023.2/include -I/tools/Xilinx/Vitis_HLS/2023.2/etc -IsrcCommon/ -O0 -g -Wall -fmessage-length=0 -std=c++11
LDFLAGS = -lOpenCL -pthread -lrt -lstdc++ -L$(XILINX_VITIS)/runtime/lib/x86_64

# Kernel compiler global settings
CLFLAGS = -t $(TARGET) --platform $(DEVICE) --save-temps

# Xclbin linker flags
LDCLFLAGS = --config design.cfg

EXECUTABLE = pass

# Output files
BINARY_CONTAINERS += $(XCLBIN)/pass.$(TARGET).$(DEVICE).xclbin
BINARY_CONTAINER_pass_OBJS += $(XCLBIN)/pass.$(TARGET).xo

# Phony targets
.PHONY: all build run exe xclbin emconfig clean cleanall reset help

# Default target
all: build run

# Build target
build: HOST_SRCS = src/$(LAB)_host.cpp
build: cleanExeBuildDir
build: $(LAB)/$(EXECUTABLE)

# Run target
run: $(LAB)/$(EXECUTABLE) $(BINARY_CONTAINERS) emconfig
	cp auxFiles/xrt.ini $(LAB)
ifeq ($(LAB),$(filter $(LAB), pipeline sync))
   ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	cd $(LAB); export XCL_EMULATION_MODE=${TARGET}; ./$(EXECUTABLE) ../$(BINARY_CONTAINERS)
   else
	cd $(LAB); ./$(EXECUTABLE) ../$(BINARY_CONTAINERS)
   endif
else
   ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	cd $(LAB); export XCL_EMULATION_MODE=${TARGET}; ./$(EXECUTABLE) ../$(BINARY_CONTAINERS) $(SIZE)
   else
	cd $(LAB); ./$(EXECUTABLE) ../$(BINARY_CONTAINERS) $(SIZE)
   endif
endif

# Build the executable
$(LAB)/$(EXECUTABLE):
	mkdir -p $(LAB)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) -o '$(LAB)/$(EXECUTABLE)' $(LDFLAGS)

# Build xclbin
xclbin: $(BINARY_CONTAINERS)

# Kernel object file rule
$(XCLBIN)/pass.$(TARGET).xo: ./src/pass.cpp
	mkdir -p $(XCLBIN)
	$(VPP) $(CLFLAGS) -c -k pass -I'$(<D)' -o'$@' '$<'

# Linking xclbin
$(BINARY_CONTAINERS): $(BINARY_CONTAINER_pass_OBJS)
	$(VPP) $(CLFLAGS) -l $(LDCLFLAGS) -o'$@' $(+)

# Emconfig rule for generating the emconfig.json
emconfig: $(LAB)/emconfig.json
$(LAB)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(LAB)

# Cleaning stuff
cleanExeBuildDir:
	-$(RMDIR) $(LAB)

clean:
	-$(RMDIR) $(XCLBIN)/{sw_emu,hw_emu}
	-$(RMDIR) workspace buf sync pipeline
	-$(RMDIR) $(XCLBIN)/.xo $(XCLBIN)/.ltx

cleanall: clean
	-$(RMDIR) $(XCLINX)/$(XCLBIN)

reset: clean
	cp auxFiles/*host.cpp src

# Help command for usage
help:
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> LAB=<pipeline/sync/buf>"
	$(ECHO) "      Command to generate the design for specified Target and Device."
	$(ECHO) "  make kernel TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform>"
	$(ECHO) "      Command compile just the kernel of the design for specified Target and Device."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
