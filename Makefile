AWS_ACCOUNT_ID := 123456789012
AWS_REGION := ca-central-1
DOCKER_DIR := ./docker
TF_MODULE_DIR := ./terragrunt/env/dev

.PHONY: apply cert docker fmt init plan setup

apply: init
	@terragrunt apply --terragrunt-working-dir=${TF_MODULE_DIR}

docker:
	docker build \
		-t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/zitadel:latest \
		-f ${DOCKER_DIR}/Dockerfile ${DOCKER_DIR}
	aws ecr get-login-password --region ${AWS_REGION} | docker login \
		--username AWS \
		--password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/zitadel:latest

cert:
	openssl \
		req \
		-nodes \
		-newkey rsa:2048 \
		-x509 -days 3650 \
		-keyout ./${DOCKER_DIR}/private.key \
		-out ./${DOCKER_DIR}/certificate.crt \
		-subj "/C=CA/ST=Ontario/L=Ottawa/O=cds-snc/OU=platform/CN=zitadel.cdssandbox.xyz/emailAddress=platform@cds-snc.ca" &&\
	chmod +r ./${DOCKER_DIR}/private.key

fmt:
	@terragrunt fmt --terragrunt-working-dir=${TF_MODULE_DIR}

init:
	@terragrunt init --terragrunt-working-dir=${TF_MODULE_DIR}

plan: init
	@terragrunt plan --terragrunt-working-dir=${TF_MODULE_DIR}

setup: cert init
	terragrunt apply \
		--target=aws_ecr_repository.zitadel \
		--terragrunt-working-dir=${TF_MODULE_DIR} &&\
	$(MAKE) docker &&\
	$(MAKE) apply
