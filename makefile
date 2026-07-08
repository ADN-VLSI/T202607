build log: 
	@mkdir -p $@
	@echo "*" > $@/.gitignore


build/$(TOP).out: build source/$(TOP).sv
	@iverilog -o build/$(TOP).out source/$(TOP).sv

.PHONY: run
run: build/$(TOP).out
	@vvp build/$(TOP).out | tee log/$(TOP)_$(shell date +%Y-%m-%d_%H-%M-%S).log

.PHONY: clean
clean:
	@rm -rf build log
	@echo -e "\033[1;33m>[om] Cleaned build and log directories.\033[0m"