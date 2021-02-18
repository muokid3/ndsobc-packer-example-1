.PHONY: tmp

run: stop start exec

up: fmt plan apply

start:
	docker container run -it -d \
		   --env TF_NAMESPACE=$$TF_NAMESPACE \
		   --env AWS_PROFILE="labs" \
		   -v /var/run/docker.sock:/var/run/docker.sock \
		   -v $$PWD:/$$(basename $$PWD) \
		   -v $$PWD/creds:/root/.aws \
		   --hostname "$$(basename $$PWD)" \
		   --name "$$(basename $$PWD)" \
		   -w /$$(basename $$PWD) \
		   bryandollery/terraform-packer-aws-alpine:14

exec:
	docker exec -it "$$(basename $$PWD)" bash || true

stop:
	docker rm -f "$$(basename $$PWD)" 2> /dev/null || true

fmt:
	time terraform fmt -recursive

plan:
	time terraform plan -out plan.out

apply:
	time terraform apply plan.out 

down:
	time terraform destroy -auto-approve 

test: copy connect

copy:
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.sandbox_ip.value' | xargs) rm -f /home/ubuntu/id_rsa
	scp -i ssh/id_rsa ssh/id_rsa ubuntu@$$(terraform output -json | jq '.sandbox_ip.value' | xargs):~
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.sandbox_ip.value' | xargs) chmod 400 /home/ubuntu/id_rsa

connect:
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.sandbox_ip.value' | xargs)

init:
	rm -rf .terraform ssh
	mkdir ssh
	time terraform init 
	ssh-keygen -t rsa -f ./ssh/id_rsa -q -N ""
