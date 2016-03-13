AWS Lambda NodeJS template
--------------------------

A template project for an AWS Lambda that read some remote GeoJSON. Mostly to test nodejs and external modules.
Kinesis stream events.



#### Install

- `npm install`

#### Test

- `npm test`

#### Deploy


Use a profile name defined in the credentials in `~/.aws/credentials`. It is `default` by default.*

**Permissions:**

Define a new policy for you AWS Lambda, the default `lambda_basic_execution` role is enough 
for our Lambda's execution:

- `make info ROLE=lambda_basic_execution PROFILE=<my profile>`


**Upload:**

- `make upload FUNCTION_NAME=node-lambda-template  REGION=eu-west-1  ROLE=lambda_basic_execution PROFILE=<you profile>`

with an existing role. You may check if it does exist with:


Then you may update within

- `make update FUNCTION_NAME=node-lambda-template   REGION=eu-west-1  PROFILE=<your profile>`


#### Utilities

We've defined some useful utilities in the Makefile which can make uploading,
updating, and invoking this Lambda a little easier.

 `make list PROFILE=toto` - List all lambda for profile _toto_ 


