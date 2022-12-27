.PHONY: intermediate final
aws_region := us-east-1
cfg_file := terraform.tfvars
packer_template := main.pkr.hcl

check:
	@if [ -z ${AWS_PROFILE} ]; then echo -e '\n\e[31mPlease first \e[5mexport\e[25m AWS_PROFILE, aborting...\e[0m'; exit 1; fi
lint:
	terraform validate
	terraform fmt -diff
	# dummy values just to validate the Packer template
	packer validate -var aws_access_key="" -var aws_secret_key="" \
		-var intermediate_nexus_ami="" -var ssh_keypair_name="" -var vpc="" \
		-var tags="{}" -var aws_region="" -var ec2_instance_type="t2.medium" \
		-var ssh_username="rocky" -var subnet="" -var tag_prefix="" \
		${packer_template}
	packer fmt ${packer_template}
init: check
	rm -rf .terraform
	terraform init -backend-config=$(cfg_file)
base: lint check
	terraform apply -var-file=$(cfg_file)
packer:
	packer build -var-file packer_cfg.json ${packer_template}
intermediate:
	cd intermediate && $(MAKE) build
final:
	cd final && $(MAKE) build
clean:
	cd intermediate && $(MAKE) destroy
	@echo 'Removing intermediate AMI image...'
	cd intermediate && $(MAKE) refresh
	$(eval AMI_ID=$(shell cd intermediate && $(MAKE) show))
	@if aws ec2 deregister-image --image-id ${AMI_ID} --region ${aws_region}; then echo "OK"; else echo "Failed"; exit 1; fi
destroy: check
	terraform destroy
docs:
	terraform-docs .

