ifeq ($(OS),Windows_NT)
  XVLOG ?= xvlog.bat
  XELAB ?= xelab.bat
  XSIM  ?= xsim.bat
else
  export SHELL=/bin/bash
  XVLOG ?= xvlog
  XELAB ?= xelab
  XSIM  ?= xsim
endif

TOP := test

# If user provided TOP matching a file in testbench/ (e.g., pll_config or apb_uart_top_linear)
ifneq ($(wildcard $(CURDIR)/testbench/$(TOP).sv),)
  MOD_IN_FILE := $(shell sed -n 's/^[[:space:]]*module[[:space:]]\+\([a-zA-Z0-9_]\+\).*/\1/p' $(CURDIR)/testbench/$(TOP).sv | head -n 1)
  ifneq ($(MOD_IN_FILE),)
    override TOP := $(MOD_IN_FILE)
  endif
else ifneq ($(wildcard $(CURDIR)/testbench/$(TOP)_tb.sv),)
  override TOP := $(TOP)_tb
endif

BUILD_DIR := $(CURDIR)/build
LOG_DIR := $(CURDIR)/log

FILELIST += -i $(CURDIR)/package
FILELIST += $(shell find $(CURDIR)/interface -name "*.sv")
FILELIST += $(shell find $(CURDIR)/source -name "*.sv")
FILELIST += $(shell find $(CURDIR)/testbench -name "*.sv")

EW_O := | grep -iE "Error:|Warning:" --color=auto || true
EWHL := | grep -iE "Error:|Warning:|" --color=auto

$(BUILD_DIR) $(LOG_DIR):
	@echo -e "\033[1;33m>\033[0m Creating $@ directory..."
	@mkdir -p $@
	@echo "*" > $@/.gitignore

TN ?= reset_test
TR ?= 1

$(BUILD_DIR)/snap_$(TOP):
	@make -s $(BUILD_DIR)
	@make -s $(LOG_DIR)
	@echo -e "\033[1;33m>\033[0m Compiling $(TOP)..."
	@cd $(BUILD_DIR) && $(XVLOG) -sv $(FILELIST) -log $(LOG_DIR)/xvlog_$(shell date +%Y%m%d_%H%M%S).log $(EW_O)
	@cd $(BUILD_DIR) && $(XELAB) $(TOP) -s snap_$(TOP) -debug all -log $(LOG_DIR)/xelab_$(TOP)_$(shell date +%Y%m%d_%H%M%S).log $(EW_O)
	@if [ ! -d $(BUILD_DIR)/xsim.dir/snap_$(TOP) ]; then \
		echo -e "\033[1;31m>\033[0m Elaboration failed! Check logs in $(LOG_DIR)"; \
		exit 1; \
	fi
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

