ENV_NAME = chiari

.PHONY: install
install:
	conda env create -f environment.yml || conda env update -f environment.yml

.PHONY: activate
activate:
	@echo "Run: conda activate $(ENV_NAME)"
