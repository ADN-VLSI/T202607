export SHELL=/bin/bash

TOP := test

BUILD_DIR := $(CURDIR)/build
LOG_DIR := $(CURDIR)/log

FILELIST += -i $(CURDIR)/include
FILELIST += -i $(CURDIR)/package
FILELIST += -i $(CURDIR)/testbench
FILELIST += $(shell find $(CURDIR)/interface -mindepth 1 -maxdepth 1 -name "*.sv")
FILELIST += $(shell find $(CURDIR)/source    -mindepth 1 -maxdepth 1 -name "*.sv")
TB_FILES := $(shell find $(CURDIR)/testbench -mindepth 1 -maxdepth 1 -name "*.sv")
ifneq ($(TOP),apb_uart_top_uvm_tb)
TB_FILES := $(filter-out %/apb_uart_top_uvm_tb.sv,$(TB_FILES))
endif
 
ifneq ($(TOP),apb_uart_top_layered_tb)
TB_FILES := $(filter-out %/apb_uart_top_layered_tb.sv,$(TB_FILES))
endif
FILELIST += $(TB_FILES)

EW_O := | grep -a -iE "Error:|Warning:" --color=auto || true
EWHL := | grep -a -iE "Error:|Warning:|" --color=auto

$(BUILD_DIR) $(LOG_DIR):
	@echo -e "\033[1;33m>\033[0m Creating $@ directory..."
	@mkdir -p $@
	@echo "*" > $@/.gitignore

XVLOG ?= xvlog
XELAB ?= xelab
XSIM  ?= xsim

TN := default
TR := 1

$(BUILD_DIR)/snap_$(TOP):
	@make -s $(BUILD_DIR)
	@make -s $(LOG_DIR)
	@echo -e "\033[1;33m>\033[0m Compiling $(TOP)..."
	@cd $(BUILD_DIR) && $(XVLOG) -sv $(FILELIST) -L uvm -log $(LOG_DIR)/xvlog_$(shell date +%Y%m%d_%H%M%S).log $(EW_O)
	@cd $(BUILD_DIR) && $(XELAB) $(TOP) -s snap_$(TOP) -debug all -log $(LOG_DIR)/xelab_$(TOP)_$(shell date +%Y%m%d_%H%M%S).log $(EW_O)
	@echo "" > $(BUILD_DIR)/snap_$(TOP)

.PHONY: run
run:
	@make -s $(BUILD_DIR)/snap_$(TOP)
	@echo -e "\033[1;33m>\033[0m Running $(TOP)..."
	@echo "--testplusarg CLI_TEST_NAME=$(TN)" > $(BUILD_DIR)/xsim_args
	@echo "--testplusarg CLI_TEST_REPEATS=$(TR)" >> $(BUILD_DIR)/xsim_args
	@cd $(BUILD_DIR) && $(XSIM) snap_$(TOP) -f xsim_args -runall -log $(LOG_DIR)/xsim_$(TOP)_$(shell date +%Y%m%d_%H%M%S).log $(EWHL)

.PHONY: all
all:
	@make -s clean
	@make -s run TOP=$(TOP) TN=$(TN) TR=$(TR)

.PHONY: clean
clean:
	@echo -e "\033[1;33m>\033[0m Cleaning $(BUILD_DIR) and $(LOG_DIR) directories."
	@rm -rf $(BUILD_DIR) $(LOG_DIR)
