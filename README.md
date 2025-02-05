# Project Overview

## `app` folder
Frontend URL: https://d34o1pq4fivep8.cloudfront.net/

<img width="757" alt="image" src="https://github.com/user-attachments/assets/ba251308-a591-4f2d-9b71-ec5fce81e476" />

`app/nodejs-api` contains lambda code and can be locally tested with AWS SAM.
The development AWS RDS is allowed for public purposely so it was easy to test Lambda code during the development.

Purpose of using SAM was get faster feedback loop during development.

AWS SAM commands required to setup the build and run the lambda function can be found in `app/nodejs-api/README.md`.

Once local development is completed the developer can push the code to GitHub. It will trigger the pipeline defined in `.github/workflows/app.yml`

Lambda CI/CD is based on Terraform, which was easy than using SAM. Because the infra was defined already with Terraform (SAM doesn't support all AWS resources required in this project) and achieving seemless ingregation between SAM and Terraform felt teredious.


## `infra` folder

The `infra` folder contains the infrastructure Terraform components required for Lambda functions.

Terraform statefile is configured be stored in s3 bucket. You can change Terraform state s3 backend configuration `infra/backend.hcl` and use the instructions in `infra/README.md` to deploy the project.

Terraform CI/CD is setup in `.github/workflows/infra.yml`

## `APP Obserability` ##

Sentry is setup to track errors:

<img width="629" alt="image" src="https://github.com/user-attachments/assets/09804c5c-ed4e-4053-9c9e-daef617cc167" />

Logs are sent to Splunk directly with http calls, and this was to avoid CloudWatch Log + Splunk ingegation cost.

<img width="638" alt="image" src="https://github.com/user-attachments/assets/5c74be2e-d112-40ce-8314-e12487afac54" />

CloudWatch Dashboard:

<img width="739" alt="image" src="https://github.com/user-attachments/assets/c847fa0c-ec5d-400d-9b95-3a160f85d8a3" />


## `Pending tasks` ##

- Bug fix in Lambda code unit test
<img width="392" alt="image" src="https://github.com/user-attachments/assets/275db6bb-e91a-44ba-8bec-c0ace1a56f8c" />

- Set up API Gateway and database logs to S3 and use AWS Firehose to send logs to Splunk to avoid CloudWatch data ingestion costs(~$0.50 per GB ingested).
- Set up an alert for anomalies.
