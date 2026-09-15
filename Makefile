TOP := test

# Convert paths to clean backslashes for native Windows shell execution
BUILD_DIR := $(subst /,\,$(CURDIR)/build)
LOG_DIR   := $(subst /,\,$(CURDIR)/log)

# Find all .sv files cleanly using native Make wildcards (avoids the Linux 'find' tool)
FILELIST := -i "$(subst /,\,$(CURDIR)/package)"
FILELIST += $(subst /,\,$(wildcard $(CURDIR)/interface/*.sv))
FILELIST += $(subst /,\,$(wildcard $(CURDIR)/source/*.sv))
FILELIST += $(subst /,\,$(wildcard $(CURDIR)/testbench/$(TOP).sv))

XVLOG ?= xvlog
XELAB ?= xelab
XSIM  ?= xsim

TN := default
TR := 1

# Create Build and Log Folders using Windows Syntax
$(BUILD_DIR):
	@echo Creating build directory...
	@if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"

$(LOG_DIR):
	@echo Creating log directory...
	@if not exist "$(LOG_DIR)" mkdir "$(LOG_DIR)"

$(BUILD_DIR)\snap_$(TOP): $(BUILD_DIR) $(LOG_DIR)
	@echo Compiling $(TOP)...
	@cd $(BUILD_DIR) && set XILINXD_LICENSE_FILE=&& set XILINX_LICENSE_BypassWebpackCheck=1&& $(XVLOG) -sv $(FILELIST) -log $(LOG_DIR)\xvlog.log
	@cd $(BUILD_DIR) && set XILINXD_LICENSE_FILE=&& set XILINX_LICENSE_BypassWebpackCheck=1&& $(XELAB) $(TOP) -s snap_$(TOP) -debug all -log $(LOG_DIR)\xelab_$(TOP).log
	@echo. > $(BUILD_DIR)\snap_$(TOP)

.PHONY: run
run: $(BUILD_DIR)\snap_$(TOP)
	@echo Running $(TOP)...
	@echo --testplusarg CLI_TEST_NAME=$(TN) > $(BUILD_DIR)\xsim_args
	@echo --testplusarg CLI_TEST_REPEATS=$(TR) >> $(BUILD_DIR)\xsim_args
	@cd $(BUILD_DIR) && set XILINXD_LICENSE_FILE=&& set XILINX_LICENSE_BypassWebpackCheck=1&& $(XSIM) snap_$(TOP) -f xsim_args -runall -log $(LOG_DIR)\xsim_$(TOP).log

.PHONY: all
all: clean run

.PHONY: clean
clean:
	@echo Cleaning build and log directories...
	@if exist "$(BUILD_DIR)" rmdir /s /q "$(BUILD_DIR)"
	@if exist "$(LOG_DIR)" rmdir /s /q "$(LOG_DIR)"