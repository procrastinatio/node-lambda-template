ifneq ($(filter info delete get invoke list update upload,$(MAKECMDGOALS)),$())
ifndef PROFILE 
$(error PROFILE not defined)
endif
endif
ifneq ($(filter delete get invoke update upload,$(MAKECMDGOALS)),$())
ifndef FUNCTION_NAME 
$(error FUNCTION_NAME not defined)
endif
endif

ifdef payload
PAYLOAD:=$(shell cat $(payload))
endif

PROFILE:=default
REGION_FROM_PROFILE=$(shell aws configure get region --profile  $(PROFILE) )
REGION := $(shell if [ '$(REGION_FROM_PROFILE)' != '' ]; then echo '$(REGION_FROM_PROFILE)'; else echo 'eu-west-1'; fi)


ifneq ($(filter info upload,$(MAKECMDGOALS)),$())
ifndef ROLE
$(error  ROLE not defined)
endif
#ARN:=$(shell aws iam get-role --role-name $(ROLE)  --profile $(PROFILE) --region $(REGION)   --query 'Role.Arn' --output text)
ARN:=$(shell aws iam get-role --role-name $(ROLE)  --profile $(PROFILE) --region $(REGION)   --query 'Role.Arn' --output text  2> /dev/null)
ifeq "$(ARN)" ""
$(error "ARN not found. Role '$(ROLE)' is probably not defined")
endif
endif

ROLE:=lambda_basic_execution
AWS_ACCOUNT_ID:=$(shell aws ec2 describe-security-groups  --profile $(PROFILE)  --region $(REGION)  --group-names 'Default'     --query 'SecurityGroups[0].OwnerId'     --output text)
#ARN=$(aws iam get-role --role-name $(ROLE)--profile borghi --query 'Role.Arn')



.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo
	@echo "Possible targets:"
	@echo "- list               List all Lambda function within the region"
	@echo "- list-event-source  List event source mappings for function $(FUNCTION_NAME)"
	@echo "- get                Get the Lambda function $(FUNCTION_NAME)"
	@echo "- upload             Build, create and upload Lambda function named $(FUNCTION_NAME)"
	@echo "- update             Subsequent update of Lambda function $(FUNCTION_NAME)"
	@echo "- invokde            Invoke function $(FUNCTION_NAME) with payload $(payload)"
	@echo "- delete             Delete Lambda function $(FUNCTION_NAME)"
	@echo
	@echo "Variables:"
	@echo "PROFILE:             ${PROFILE}"
	@echo "REGION:              ${REGION} "
	@echo "FUNCTION_NAME:       ${FUNCTION_NAME}"
	@echo

info:
	@echo "AWS_ACCOUNT_ID: $(AWS_ACCOUNT_ID)"
	@echo "ARN :           ${ARN}"

delete:
	aws lambda delete-function \
		--region $(REGION) \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME)

get:
	aws lambda get-function \
		--region $(REGION) \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME)

invoke:
	aws lambda invoke \
		--region $(REGION) \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME) \
		--payload  '$(PAYLOAD)' \
		--log-type Tail \
		/dev/stdout

list: 
	echo $(PROFILE) ${REGION}
	aws lambda list-functions \
		--profile $(PROFILE) \
		--region $(REGION)

list-event-sources:
	aws lambda list-event-source-mappings \
		--profile $(PROFILE) \
		--region $(REGION)

update:
	@npm install
	@zip -r ./MyLambda.zip * -x *.json *.zip test.js
	aws lambda update-function-code \
		--region $(REGION) \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://MyLambda.zip

upload:
	@npm install 
	@zip -r ./MyLambda.zip * -x *.json *.zip test.js
	aws lambda create-function \
		--region $(REGION) \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://MyLambda.zip \
		--handler MyLambda.handler \
		--runtime nodejs \
		--timeout 15 \
		--memory-size 128 \
		--role $(ARN)

test:
	@npm test


.PROXY: delete get invoke list list-event-sources update upload test
