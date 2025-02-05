# Project Overview

## `app` Folder
Frotend URL: https://d34o1pq4fivep8.cloudfront.net/

`app/nodejs-api` contains lambda code and can be locally tested with AWS SAM.
The development AWS RDS is allowed for public purposely so it was easy to test Lambda code during the development.
Purpose of using SAM is have faster feedback loop for development.

Please refer `app/nodejs-api/README.md` for detailed setup

SAM command required to setup the build and run the lamda function can be found in the subdirectory folder.

Once local development is completed the developer can push the code to GitHub. I will trigger the pipeline defined in `.github/workflows/app.yml`
Lambda CI/CD is based on terraform, which was easy to than using SAM. Because the Infa was defined already with Terraform (SAM doesn't support all AWS resources required in this project) and achieing seemless ingregation between SAM and Terraform felt teredious.

APP Obserability
Sentry is setup to track errors
Logs are sent to Splunk directly with http calls, and this was to avoid CloudWatch Log + Splunk ingegation cost.

## `infra` Folder

The `infra` folder contains the infrastructure Terraform components required to deploy and run the Lambda functions.

Terraform statefile is configured be stored in s3 bucket. You can change s3 configuration `infra/backend.hcl` and use the instruction in `infra/README.md` to deploy the project.

Terraform CI/CD is setup in `.github/workflows/infra.yml`