.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> EDGE_COMMON_SW=<rootfs and kernel image path>"
	$(ECHO) "      Command to generate the design for specified Target and Shell."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and EDGE_COMMON_SW is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO)  "  make test DEVICE=<FPGA platform>"
	$(ECHO)  "     Command to run the application. This is same as 'check' target but does not have any makefile dependency."
	$(ECHO)  ""
	$(ECHO) "  make sd_card TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> EDGE_COMMON_SW=<rootfs and kernel image path>"
	$(ECHO) "      Command to prepare sd_card files."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and EDGE_COMMON_SW is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> EDGE_COMMON_SW=<rootfs and kernel image path>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and EDGE_COMMON_SW is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> EDGE_COMMON_SW=<rootfs and kernel image path>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and EDGE_COMMON_SW is required for SoC shells"
	$(ECHO) ""

# Points to top directory of Git repository
COMMON_REPO = ../
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))
# The absolute dir of the 'common' dir, i.e. ABS_COMMON_REPO = /home/user2/workspace/dezheng/pipecnn_ocl

TARGET := hw

# DEVICE := xilinx_u50_gen3x16_xdma_201920_3
# HOST_ARCH := x86

DEVICE := xilinx_zcu102_base_202010_1
HOST_ARCH := aarch64
EDGE_COMMON_SW := /opt/petalinux/2020.1/
SYSROOT := 

include ./utils.mk

XSA := $(call device2xsa, $(DEVICE))
TEMP_DIR := ./_x.$(TARGET).$(XSA)
BUILD_DIR := ./build_dir.$(TARGET).$(XSA)

# SoC variables
RUN_APP_SCRIPT = run_app.sh
PACKAGE_OUT = package.$(TARGET)

LAUNCH_EMULATOR = $(PACKAGE_OUT)/launch_$(TARGET).sh
RESULT_STRING = TEST PASSED

VPP := v++
SDCARD := sd_card

#Include Libraries
include $(ABS_COMMON_REPO)/common/includes/opencl/opencl.mk
include $(ABS_COMMON_REPO)/common/includes/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS)
HOST_SRCS += $(xcl2_SRCS)
CXXFLAGS += $(opencl_CXXFLAGS) -Wall -O0 -g -std=c++11
LDFLAGS += $(opencl_LDFLAGS)

HOST_INCS += $(COMMON_REPO)/common

HOST_SRCS += host/main.cpp
HOST_SRCS += $(wildcard $(COMMON_REPO)/common/*.cpp)
DEVICE_SRCS += device/conv_pipe_xilinx.cl

# Host compiler global settings
CXXFLAGS += -fmessage-length=0 -DXILINX
LDFLAGS += -lrt -lstdc++ 

ifneq ($(HOST_ARCH), x86)
	LDFLAGS += --sysroot=$(SYSROOT)
endif

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --jobs 16 --platform $(DEVICE) --save-temps 

EXECUTABLE = run.exe
CMD_ARGS = $(BUILD_DIR)/conv.xclbin
EMCONFIG_DIR = $(TEMP_DIR)
EMU_DIR = $(SDCARD)/data/emulation

BINARY_CONTAINERS += $(BUILD_DIR)/conv.xclbin
BINARY_CONTAINER_OBJS += $(TEMP_DIR)/conv.xo

CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig sd_card

.PHONY: exe
exe: $(EXECUTABLE)

.PHONY: build
build: check-vitis $(BINARY_CONTAINERS)

# Building kernel
$(BINARY_CONTAINER_OBJS): $(DEVICE_SRCS)
	mkdir -p $(TEMP_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(TEMP_DIR) -c -I'$(<D)' -o'$@' '$<'
$(BUILD_DIR)/conv.xclbin: $(BINARY_CONTAINER_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) -o'$@' $(+)

# Building Host
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS) $(HOST_INCS)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS) -I $(HOST_INCS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
ifeq ($(HOST_ARCH), x86)
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(BUILD_DIR)/conv.xclbin
else
	$(ABS_COMMON_REPO)/common/utility/run_emulation.pl "./${LAUNCH_EMULATOR} | tee run_app.log" "./${RUN_APP_SCRIPT} $(TARGET)" "${RESULT_STRING}" "7"
endif
else
ifeq ($(HOST_ARCH), x86)
	./$(EXECUTABLE) $(BUILD_DIR)/conv.xclbin
endif
endif

.PHONY: host
host:$(EXECUTABLE)

.PHONY: test
test: $(EXECUTABLE)
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
ifeq ($(HOST_ARCH), x86)
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(BUILD_DIR)/conv.xclbin
else
	$(ABS_COMMON_REPO)/common/utility/run_emulation.pl "./${LAUNCH_EMULATOR} | tee embedded_run.log" "./${RUN_APP_SCRIPT} $(TARGET)" "${RESULT_STRING}" "7"
endif
else
ifeq ($(HOST_ARCH), x86)
	./$(EXECUTABLE) $(BUILD_DIR)/conv.xclbin
else
	$(ECHO) "Please copy the content of sd_card folder and data to an SD Card and run on the board"
endif
endif

# .PHONY: debug
# debug: $(EXECUTABLE)
# ifeq ($(HOST_ARCH), x86)
# 	vitis -debug -flow data_center -target sw_emu -exe ./$(EXECUTABLE) -kernels $(BUILD_DIR)/conv.xclbin
# endif

sd_card: gen_run_app
ifneq ($(HOST_ARCH), x86)
	$(VPP) -t $(TARGET) --jobs 16 --platform $(DEVICE) -p $(BUILD_DIR)/conv.xclbin --package.out_dir $(PACKAGE_OUT) --package.rootfs $(EDGE_COMMON_SW)/rootfs.ext4 --package.sd_file $(SD_IMAGE_FILE) --package.sd_file $(RUN_APP_SCRIPT) --package.sd_file $(EXECUTABLE) -o conv.xclbin
endif

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv 
	-$(RMDIR) src/*.ll *v++* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) build_dir* sd_card*
	-$(RMDIR) package.*
	-$(RMDIR) _x* *xclbin.run_summary qemu-memory-_* emulation/ _vimage/ pl* start_simulation.sh *.xclbin

