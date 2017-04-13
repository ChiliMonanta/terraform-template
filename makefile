
ifeq ($(env),global)
	TFVARS="global.tfvars"
	STATE=output
	base="environments/global"
else ifeq ($(env),prod)
	TFVARS="prod.tfvars"
	STATE=output
	base="environments/production"
else ifeq ($(env),stage)
	TFVARS="staging.tfvars"
	STATE=output
	base="environments/staging"
else
	TFVARS="dev.tfvars"
	STATE=output
	base="environments/development"
endif

get:
	cd $(base) && terraform get

plan: get
	cd $(base) && terraform plan -var-file=$(TFVARS) -state="$(STATE)/$(env).tfstate"

destroy: get
	cd $(base) && terraform destroy -var-file=$(TFVARS) -state="$(STATE)/$(env).tfstate"

apply: get
	cd $(base) && terraform apply -var-file=$(TFVARS) -state="$(STATE)/$(env).tfstate"

clean:
	cd $(base) && rm -rf output
