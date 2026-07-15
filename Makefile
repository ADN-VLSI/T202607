export SHELL=/bin/bash

TOP := test

BUILD_DIR := $(CURDIR)/build
LOG_DIR := $(CURDIR)/log

FILELIST += $(CURDIR)/package/pkg_101.sv
FILELIST += $(shell find $(CURDIR)/interface -name "*.sv")
FILELIST += $(shell find $(CURDIR)/source -name "*.sv")
FILELIST += $(shell find $(CURDIR)/testbench -name "*.sv")

$(BUILD_DIR) $(LOG_DIR):
	@echo -e "\033[1;33m>\033[0m Creating $@ directory..."
	@mkdir -p $@
	@echo "*" > $@/.gitignore

$(BUILD_DIR)/snap_$(TOP):
	@make -s $(BUILD_DIR)
	@make -s $(LOG_DIR)
	@echo -e "\033[1;33m>\033[0m Compiling $(TOP)..."
	@cd $(BUILD_DIR) && xvlog -sv $(FILELIST) -log $(LOG_DIR)/xvlog_$(shell date +%Y%m%d_%H%M%S).log
	@cd $(BUILD_DIR) && xelab $(TOP) -s snap_$(TOP) -debug all -log $(LOG_DIR)/xelab_$(TOP)_$(shell date +%Y%m%d_%H%M%S).log
	@echo "" > $(BUILD_DIR)/snap_$(TOP)

.PHONY: run
run:
	@make -s $(BUILD_DIR)/snap_$(TOP)
	@echo -e "\033[1;33m>\033[0m Running $(TOP)..."
	@cd $(BUILD_DIR) && xsim snap_$(TOP) -runall -log $(LOG_DIR)/xsim_$(TOP)_$(shell date +%Y%m%d_%H%M%S).log

.PHONY: all
all:
	@make -s clean
	@make -s run

.PHONY: clean
clean:
	@echo -e "\033[1;33m>\033[0m Cleaning $(BUILD_DIR) and $(LOG_DIR) directories."
	@rm -rf $(BUILD_DIR) $(LOG_DIR)
