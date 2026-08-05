# Secure Edge-Delivered Static Site Infrastructure

A cloud-native static hosting infrastructure built for modern web applications (**Vite / Tailwind CSS / SPA**). Built to simulate a secure cloud edge delivery environment, this project serves as an engineering case study to explore cloud infrastructure provisioning patterns, specifically integrating **Amazon S3**, **AWS CloudFront (with Origin Access Control - OAC)**, **AWS WAFv2**, **Amazon Route 53**, and **Amazon CloudWatch** using **Terraform** for Infrastructure as Code (IaC).

The primary focus of this application is not on complex frontend business logic, but rather on automated provisioning, orchestrating managed edge services, implementing a zero-trust storage perimeter, and mastering the AWS ecosystem (via LocalStack). It is a case study designed to make structural cloud-native concepts tangible, handling edge network routing, declarative variable constraints, secure origin isolation, infrastructure modularity, and operational observability.

## Table of Contents

- [Prerequisites](#prerequisites)
- [How to Run](#how-to-run)
- [Project Structure](#project-structure)
- [Architecture & Design Principles](#architecture--design-principles)
- [Infrastructure Deep Dive](#infrastructure-deep-dive)
- [CI/CD & Automation Gates](#cicd--automation-gates)
- [Known Limitations & Pragmatic Trade-offs](#known-limitations--pragmatic-trade-offs)

## Prerequisites

Ensure you have the following installed to run this project efficiently in your local environment:

- **[Node.js](https://nodejs.org/en/download)**
- **[Terraform](https://developer.hashicorp.com/terraform/install)**
- **[Docker](https://www.docker.com/)** (Required to run the LocalStack emulation container)
- **[LocalStack AWS CLI (awslocal)](https://docs.localstack.cloud/aws/connecting/aws-cli/)** (A thin wrapper around the AWS CLI pre-configured for LocalStack endpoints)

## How to Run

Follow these granular steps to spin up the local cloud environment, compile frontend assets, and provision the complete infrastructure.

### 1. Clone the Repository

Download the source code to your local machine:

```bash
git clone https://github.com/kauatwn/tf-s3-static-hosting.git
```

### 2. Navigate into the Project Folder

```bash
cd tf-s3-static-hosting
```

### 3. Start the Local Cloud Environment

Spin up the LocalStack Pro container in the background to emulate the AWS cloud services locally without incurring real costs:

```bash
docker-compose up -d
```

### 4. Install Frontend Dependencies

Install all packages using a frozen lockfile to guarantee development environment consistency:

```bash
pnpm install --frozen-lockfile
```

### 5. Build the Vite Web Application

Compile and optimize the static frontend production assets:

```bash
pnpm run build
```

_Note: This generates the highly optimized production build output inside the local `./dist` directory._

### 6. Navigate to the Environment Directory

Move to the specific Terraform development environment folder before executing provisioning tasks:

```bash
cd infra/environments/dev
```

### 7. Initialize Terraform

Download the required provider plugins and initialize the local state backend:

```bash
terraform init
```

### 8. Plan the Infrastructure

Generate and inspect an execution plan to preview all resources to be built before making changes:

```bash
terraform plan -out=tfplan
```

### 9. Apply the Infrastructure

Execute the verified plan non-interactively to provision your local AWS resources:

```bash
terraform apply -input=false tfplan
```

> [!TIP]
> Terraform will output the dynamically generated `s3_bucket_name`, `cloudfront_distribution_id`, `cloudfront_domain_name`, and `route53_name_servers` upon completion.

### 10. Deploy Artifacts

Upload the static files to the completely private S3 bucket:

```bash
awslocal s3 sync ../../../dist s3://$(terraform output -raw s3_bucket_name) --delete
```

### 11. Invalidate Edge Cache

Purge the CloudFront distribution cache to guarantee that your updates are instantly available globally:

```bash
awslocal cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/*"
```

## Project Structure

The codebase is organized following **Modular IaC principles**, cleanly segregating reusable infrastructure blocks (Pure Modules) from environmental orchestration (Glue Code) and frontend source code.

```plaintext
tf-s3-static-hosting/
├── .github/workflows/
│   └── pipeline.yml                      # GitHub Actions automated workflow
├── dist/                                 # Vite production build output
├── src/
├── infra/
│   ├── environments/
│   │   └── dev/                          # Development environment entrypoint
│   │       ├── main.tf                   # Root orchestration & Glue Code
│   │       ├── outputs.tf                # CI/CD & CLI integration outputs
│   │       ├── providers.tf              # LocalStack AWS Provider configuration
│   │       ├── variables.tf              # Environment variables & Input Validations
│   │       └── terraform.tfvars.example  # Example values for local deployment
│   └── modules/
│       ├── cdn/                          # CloudFront, OAC, Security Headers & SPA Routing
│       ├── dns/                          # Route 53 Zone & Alias Records (A/AAAA)
│       ├── monitoring/                   # CloudWatch Alarms (5xx errors, WAF blocks)
│       ├── storage/                      # Private S3 Bucket & Public Access Blocks
│       └── waf/                          # WAFv2 Web ACL, Rate Limiting & OWASP Rules
├── docker-compose.yml
└── package.json
```

## Architecture & Design Principles

This repository prioritizes a **Serverless Edge-Delivered Architecture** coupled with strict **Inversion of Control (IoC)** patterns inside Terraform.

### 1. Edge-Secured Request Lifecycle

_The synchronous edge request pipeline follows a direct flow, from DNS resolution in Route 53, passing through WAFv2 and CloudFront caching, to the private origin in S3:_

- **The Entrypoint:** The client resolves the domain via **Amazon Route 53** using `A`/`AAAA` Alias records pointing directly to the CDN edge network.
- **The Edge Perimeter:** Before reaching any storage layer, requests pass through **AWS WAFv2** for Layer 7 inspection, including rate limiting and AWS Managed Rules.
- **The Delivery Cache:** **AWS CloudFront** processes TLS termination, applies HTTP security headers, manages edge caching policies, and handles Single Page Application client-side routing rewrites.
- **The Storage Vault:** The content resides in an **Amazon S3** bucket sealed entirely from the internet by an explicit public access block. It accepts read operations only when authorized through **CloudFront Origin Access Control (OAC)**.

### 2. Design Patterns & Architectural Features

| Feature / Pattern      | Usage Scenario                                                                    | Implementation                                                                                                           |
| ---------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Pure Modules (IoC)** | Eliminating circular dependencies and tight resource coupling within HCL modules. | Reusable modules in `/infra/modules/` accept dependencies as typed variables; the root module acts as the **Glue Code**. |
| **Zero-Trust Origin**  | Preventing users from bypassing the CDN and accessing S3 directly.                | Enforced by `aws_s3_bucket_public_access_block` and an explicit CloudFront Service Principal bucket policy.              |
| **Fail-Fast Typing**   | Catching naming and configuration errors before requests reach the AWS API.       | Terraform `validation {}` blocks with structural regular expressions inside the environment configuration.               |
| **SPA Client Routing** | Preventing HTTP 403/404 failures when users access client-side routes directly.   | CloudFront `custom_error_response` maps origin errors back to `/index.html` with a `200 OK` response.                    |
| **Proactive Metrics**  | Detecting origin failures and unusual traffic patterns.                           | **Amazon CloudWatch Alarms** tracking CloudFront `5xxErrorRate` and WAF `BlockedRequests` metrics.                       |

### 3. Pure Modules & Glue Code

The Terraform modules follow a **Pure Modules** approach. Individual modules declare what they need through typed input variables rather than directly depending on resources managed by other modules.

The root module at `infra/environments/dev/main.tf` acts as the **Glue Code**, responsible for connecting modules and explicitly injecting their dependencies.

This approach improves:

- **Reusability:** Modules can be used in different infrastructure contexts without being tied to specific resources.
- **Testability:** Individual modules can be validated independently.
- **Maintainability:** Infrastructure relationships remain visible at the environment level.
- **Dependency Management:** Module relationships are explicitly defined instead of being hidden inside reusable components.

This avoids tightly coupled designs such as an S3 module directly requiring a CloudFront distribution ID to function.

## Infrastructure Deep Dive

### 1. Variables Management & Validation

Environment variables use strict Terraform typing to group related configuration cohesively. Critical inputs include `validation {}` blocks following a **Fail-Fast** approach, preventing invalid configurations from reaching the AWS API.

For example, S3 bucket naming constraints can be validated using regular expressions before Terraform attempts to provision the resource.

Resource tagging is standardized through centralized Terraform `locals`, allowing common metadata to be consistently applied across infrastructure resources.

### 2. Storage Layer (`storage`)

The `storage` module provisions the private S3 origin.

The bucket uses `aws_s3_bucket_public_access_block` to prevent public access. No public read access is required because objects are served through CloudFront.

Access to the origin is restricted to the CloudFront distribution through **Origin Access Control (OAC)**, creating a clear security boundary between the public edge and the storage layer.

### 3. Edge Delivery & Security (`cdn` & `waf`)

The `cdn` and `waf` modules provide the public delivery and security layer.

- **CloudFront OAC:** Uses Origin Access Control and SigV4 request signing to authenticate CloudFront requests to the S3 bucket.
- **WAFv2 Web ACL:** Attaches a Web Application Firewall to CloudFront, using IP rate limiting and AWS Managed Rules Common Rule Set.
- **SPA Routing Support:** CloudFront intercepts `403` and `404` responses generated by the S3 origin and maps them to `/index.html` with a `200 OK` response, allowing the Vite client-side router to handle the requested route.
- **Security Headers Policy:** Injects `Strict-Transport-Security`, `X-Content-Type-Options`, and `X-Frame-Options` directly at the edge.
- **Edge Caching:** CloudFront caches static assets at edge locations, reducing repeated requests to the S3 origin.

### 4. DNS Resolution (`dns`)

The `dns` module manages the Amazon Route 53 Hosted Zone and creates `A` and `AAAA` Alias records pointing to the CloudFront distribution.

This allows both IPv4 and IPv6 clients to resolve the application through the global CloudFront network.

### 5. Observability (`monitoring`)

The `monitoring` module provisions **Amazon CloudWatch Alarms** for infrastructure-level operational visibility.

The current configuration monitors:

- CloudFront `5xxErrorRate`, with an alert threshold of 5%.
- WAF `BlockedRequests`, with an alert threshold of 100 requests within a 5-minute evaluation period.

These metrics provide visibility into both potential origin failures and unusual traffic patterns.

## CI/CD & Automation Gates

The workflow configured in `pipeline.yml` provides end-to-end validation against an ephemeral LocalStack environment inside the continuous integration runner.

### Continuous Integration (`ci-build`)

The CI stage:

1. Validates code formatting through `format:check`.
2. Installs frontend dependencies using `pnpm install --frozen-lockfile`.
3. Builds the Vite application.
4. Uploads the generated `dist` directory as a workflow artifact.

This separates application compilation from infrastructure deployment and ensures that only successfully built frontend artifacts proceed to deployment.

### Continuous Deployment (`cd-deploy-localstack`)

The deployment stage:

1. Bootstraps an isolated LocalStack environment.
2. Runs Terraform formatting checks with `terraform fmt -check`.
3. Initializes Terraform.
4. Runs `terraform validate`.
5. Generates the Terraform execution plan.
6. Applies the infrastructure without manual input.
7. Downloads the frontend build artifact.
8. Synchronizes the compiled assets to S3.
9. Invalidates the CloudFront distribution cache.

This allows the entire infrastructure provisioning and static asset deployment process to be validated automatically inside the CI environment.

## Known Limitations & Pragmatic Trade-offs

As an engineering case study centered around serverless edge delivery, specific architectural decisions impose limitations that should be considered for public production workloads.

| Feature / Decision       | Usage Scenario                                                                                 | Implementation / Trade-off                                                                                                                                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Vite SPA Fallback**    | Serving Single Page Applications where client-side routes do not exist as physical S3 objects. | CloudFront maps `403/404` responses to `/index.html`. _Trade-off: True HTTP 404 responses and server-side rendering are not available in this pure static setup._                                                                   |
| **WAF Rate Limiting**    | Reducing abusive traffic and unnecessary CloudFront requests.                                  | Uses a fixed request threshold and evaluation window. _Trade-off: The threshold must be tuned carefully to avoid blocking legitimate users sharing the same public IP through corporate NAT gateways._                              |
| **LocalStack Emulation** | Testing infrastructure locally without recurring AWS costs or real cloud credentials.          | Uses LocalStack-specific provider configuration and mock credentials. _Trade-off: Global CloudFront behavior, geographic latency, edge propagation, and production network characteristics cannot be perfectly reproduced locally._ |
| **OAC vs OAI**           | Restricting S3 access exclusively to CloudFront.                                               | Uses the modern **Origin Access Control (OAC)** model instead of the legacy **Origin Access Identity (OAI)** approach, providing SigV4-based request signing.                                                                       |

### SPA Error Rewrite & SEO

The SPA fallback provides a convenient mechanism for client-side routing, but it has an SEO trade-off.

Because CloudFront returns `/index.html` with `200 OK` for routes that do not correspond to actual S3 objects, nonexistent routes cannot naturally return a true HTTP `404` response.

For SEO-critical applications, the architecture would need to evolve toward server-side or hybrid rendering, potentially using services such as Lambda@Edge or CloudFront Functions where appropriate.

### Local Emulation Boundaries

LocalStack provides an efficient environment for validating Terraform configuration and deployment workflows without incurring AWS infrastructure costs.

However, it cannot perfectly reproduce the behavior of the AWS global edge network. Characteristics such as geographical latency, global edge propagation, regional cache behavior, and production TLS/network performance may differ from real AWS infrastructure.

LocalStack should therefore be treated as an **infrastructure development and validation environment**, rather than a complete replacement for production AWS testing.
