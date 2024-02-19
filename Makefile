.PHONY: get_kubeconfig patch_manifests apply_manifests connect_apiserver disconnect_apiserver test_deny test_allow info show_ec2_kind_ssh show_ec2_proxy_ssh check_ec2_kind_ready check_ec2_proxy_ready

MANIFESTS_FOLDER = kubernetes
TERRAFORM_FOLDER = terraform
VM_KIND_NAME = $(shell cat $(TERRAFORM_FOLDER)/terraform.tfstate | jq -r '.resources[] | select(.module == "module.ec2_kind") | select(.instances[]?.attributes?.tags.Name != null) | .instances[].attributes.tags.Name')
VM_KIND_IP = $(shell cat $(TERRAFORM_FOLDER)/terraform.tfstate | jq -r '.resources[] | select(.module == "module.ec2_kind") | select(.instances[]?.attributes?.public_ip != null) | .instances[].attributes.public_ip')
VM_PROXY_NAME = $(shell cat $(TERRAFORM_FOLDER)/terraform.tfstate | jq -r '.resources[] | select(.module == "module.ec2_proxy") | select(.instances[]?.attributes?.tags.Name != null) | .instances[].attributes.tags.Name')
VM_PROXY_IP = $(shell cat $(TERRAFORM_FOLDER)/terraform.tfstate | jq -r '.resources[] | select(.module == "module.ec2_proxy") | select(.instances[]?.attributes?.public_ip != null) | .instances[].attributes.public_ip')
KUBECONFIG = $(shell ls $(TERRAFORM_FOLDER)/*.config | awk '{print $$1}')
SSH_FWD_PID = $(shell ps -fe | grep "6443:localhost:6443" | grep -v grep | awk '{print $$2}')

get_kubeconfig:
	rm -rf $(TERRAFORM_FOLDER)/*.config
	ssh -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_KIND_IP) sudo cat /install/data/$(VM_KIND_NAME).config > $(TERRAFORM_FOLDER)/$(VM_KIND_NAME).config

patch_manifests:
	proxy_ip=$(VM_PROXY_IP) j2 $(MANIFESTS_FOLDER)/cec_proxy.j2 > $(MANIFESTS_FOLDER)/cec_proxy.yaml

apply_manifests: get_kubeconfig patch_manifests connect_apiserver
	KUBECONFIG=$(KUBECONFIG) kubectl apply -f $(MANIFESTS_FOLDER)/cec_proxy.yaml
	KUBECONFIG=$(KUBECONFIG) kubectl apply -f $(MANIFESTS_FOLDER)/cnp_proxy.yaml

connect_apiserver:
	ssh -fN -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_KIND_IP) -L 6443:localhost:6443

disconnect_apiserver:
	kill -9 $(SSH_FWD_PID)

test_deny:
	KUBECONFIG=$(KUBECONFIG) kubectl exec -it curl -n test-deny -- curl -Lk -sI -m 5 -o /dev/null -w %{http_code}  https://www.roche.com

test_allow:
	KUBECONFIG=$(KUBECONFIG) kubectl exec -it curl -n test-allow -- curl -Lk -sI -m 5 -o /dev/null -w %{http_code}  https://www.roche.com

# Utils
info:
	@echo "VM_KIND_NAME: $(VM_KIND_NAME)"
	@echo "VM_KIND_IP: $(VM_KIND_IP)"
	@echo "VM_PROXY_NAME: $(VM_PROXY_NAME)"
	@echo "VM_PROXY_IP: $(VM_PROXY_IP)"
	@echo "KUBECONFIG: $(KUBECONFIG)"
	@echo "SSH_FWD_PID: $(SSH_FWD_PID)"

show_ec2_kind_ssh:
	@echo "ssh -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_KIND_IP) -L 6443:localhost:6443"

show_ec2_proxy_ssh:
	@echo "ssh -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_PROXY_IP)"

check_ec2_kind_ready:
	@(ssh -oStrictHostKeyChecking=no -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_KIND_IP) [ -f "/setup-complete" ] && echo "$(VM_KIND_NAME) setup is completed!" || echo "$(VM_KIND_NAME) is still being setup, please wait...")

check_ec2_proxy_ready:
	@(ssh -oStrictHostKeyChecking=no -i $(TERRAFORM_FOLDER)/id_rsa ubuntu@$(VM_PROXY_IP) [ -f "/setup-complete" ] && echo "$(VM_PROXY_NAME) setup is completed!" || echo "$(VM_PROXY_NAME) is still being setup, please wait...")

