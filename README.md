# Project Overview

## `app` Folder
`app/nodejs-api` contains lambda code and can be locally tested with AWS SAM.
The development AWS RDS is allowed for public purposely so it was easy to test Lambda code during the development.
Purpose of using SAM is have faster feedback loop for development.

SAM command required to setup the build and run the lamda function can be found in the subdirectory folder.

Once local development is completed the developer can push the code to GitHub. I will trigger the pipeline defined in `.github/app.yml`
Lambda CI/CD is based on terraform, which was easy to than using SAM. Because the Infa was defined already with Terraform (SAM doesn't support all AWS resources required in this project) and achieing seemless ingregation between SAM and Terraform felt teredious.

APP Obserability
Sentry is setup to track errors
Logs are sent to Splunk directly with http calls, and this was to avoid CloudWatch Log + Splunk ingegation cost.

Ideally we should use one platform for obserability reduce the context switching and improve MTTR.
OpenTelemtry

The `app` folder contains the source code for the various Lambda functions included in this project. Each subfolder within `app` represents a distinct Lambda function, with its own codebase, dependencies, and configuration files.

## `infa` Folder

The `infa` folder contains the infrastructure components required to deploy and run the Lambda functions. This includes configuration files, scripts, and templates for setting up the necessary cloud resources and services.

## `app` Folder

The `app` folder contains the source code for the various applications included in this project. Each subfolder within `app` represents a distinct application, with its own codebase, dependencies, and configuration files.

### Subfolders:
- **`app1`**: This application is responsible for handling user authentication and authorization.
- **`app2`**: This application manages the core business logic and data processing.
- **`app3`**: This application provides the user interface and frontend components.

## `infa` Folder

The `infa` folder contains the infrastructure components required to deploy and run the applications. This includes configuration files, scripts, and templates for setting up the necessary cloud resources and services.

### Subfolders:
- **`terraform`**: Contains Terraform scripts for provisioning cloud infrastructure.
- **`ansible`**: Contains Ansible playbooks for configuration management and deployment automation.
- **`scripts`**: Contains various utility scripts for managing the infrastructure and applications.

By organizing the project in this manner, we ensure a clear separation of concerns and make it easier to manage and maintain the codebase.