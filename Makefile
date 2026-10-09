# Atajos para la demo. En Windows: Git Bash o WSL.
# Credenciales siempre por variables de entorno (ARM_*, FABRIC_*, GITHUB_TOKEN).

VARS ?= environments/akanemar-demo.tfvars
TF   := terraform
PROJECT := $(shell grep -E '^project_name' $(VARS) | cut -d'"' -f2)
OPS     := FABRIC_PROJECT_NAME=$(PROJECT) FABRIC_CAPACITY_NAME=$$($(TF) output -raw capacity_name) bash scripts/fab-ops.sh

.PHONY: help init plan capacity apply status resume pause run tables optimize destroy

help:
	@echo "init      terraform init"
	@echo "plan      terraform plan con $(VARS)"
	@echo "capacity  apply solo de la capacity (primer despliegue escalonado)"
	@echo "apply     apply completo: workspaces, grupos, repo de contenido, budget"
	@echo "status | resume | pause        capacity y workspaces via fab"
	@echo "run ENV=test | tables ENV=test | optimize ENV=test"
	@echo "destroy   borra todo lo creado (pide confirmacion)"

init:
	$(TF) init

plan:
	$(TF) plan -var-file=$(VARS)

capacity:
	$(TF) apply -var-file=$(VARS) -target=module.capacity

apply:
	$(TF) apply -var-file=$(VARS)

status resume pause:
	$(OPS) $@

ENV ?= test
run tables optimize:
	$(OPS) $@ $(ENV)

destroy:
	$(TF) destroy -var-file=$(VARS)
