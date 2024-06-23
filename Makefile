AWS_ACCOUNT_ID := 571510889204
AWS_REGION := ca-central-1
DOCKER_DIR := ./docker
TF_MODULE_DIR := ./terragrunt/env/dev

.PHONY: apply docker fmt init plan setup

apply: init
	@terragrunt apply --terragrunt-working-dir=${TF_MODULE_DIR}

docker:
	docker build \
		-t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/zitadel:latest \
		-f ${DOCKER_DIR}/Dockerfile .
	aws ecr get-login-password --region ${AWS_REGION} | docker login \
		--username AWS \
		--password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/zitadel:latest

fmt:
	@terragrunt fmt --terragrunt-working-dir=${TF_MODULE_DIR}

init:
	@terragrunt init --terragrunt-working-dir=${TF_MODULE_DIR}

plan: init
	@terragrunt plan --terragrunt-working-dir=${TF_MODULE_DIR}

setup: init
	terragrunt apply \
		--target=aws_ecr_repository.zitadel \
		--terragrunt-working-dir=${TF_MODULE_DIR}
	$(MAKE) docker
	terragrunt apply
