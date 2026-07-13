export SHELL=/bin/bash

build log:
	@echo -e "\033[1;33m>\033[0m Creating $@ directory..."
	@mkdir -p $@
	@echo "*" > $@/.gitignore

build/$(TOP).out: build source/$(TOP).sv
	@echo -e "\033[1;33m>\033[0m Compiling $(TOP)..."
	@iverilog -o build/$(TOP).out source/$(TOP).sv

.PHONY: run
run: build/$(TOP).out log
	@echo -e "\033[1;33m>\033[0m Running simulation for $(TOP)..."
	@vvp build/$(TOP).out | tee log/$(TOP)_$(shell date +%Y%m%d_%H%M%S).log

.PHONY: clean
clean:
	@rm -rf build log
	@echo -e "\033[1;33m>\033[0m Cleaned build and log directories."
