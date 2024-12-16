# Let's Build It: URL Shortener in .NET

Welcome to the ["Let's Build It: URL Shortener in .NET"](https://dometrain.com/course/lets-build-it-url-shortener-in-dotnet/?ref=github) course on Dometrain! 
This course takes you on a journey through building a production-ready URL Shortener system from conception to production. 
This repository contains the source code for the course, which you can use to follow along.

## Getting Started

The **main branch** contains the most up-to-date version of the code, reflecting the latest improvements, updates, and fixes. 
If you're following along with the course, the final version of the code for each section is available on its corresponding branch. 
Below is the link to each section. You can switch to any section branch to access the exact code snapshot for that course part. 

### Sections

- [4 - Development Environment and Continuous Integration](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/04)
- [5 - Infrastructure as Code](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/05)
- [6 - Managing Secrets](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/06)
- [7 - Developing the URL Shortening Feature](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/07)
- [8 - Generating Unique Tokens](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/08)
- [9 - Implementing Authentication](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/09)
- [10 - Implementing URL Redirection](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/10)
- [11 - Developing URL Listing Feature](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/11)
- [12 - Building the Client Web Application](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/12)
- 13 - Exercise
    - [13.1 - Start](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/13)
    - [13.2 - Solution](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/13)
- [14 - Implementing Health Checks](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/14)
- [15 - Setting Up Telemetry](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/15)
- [16 - Integrating Azure Front Door](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/16)
- [17 - Implementing Network Security](https://github.com/Dometrain/lets-build-it-url-shortener-in-dotnet/tree/section/17)
 


## Infrastructure Costs Recommendations

This course aims to build the foundations of a globally scalable application. For that, it uses expensive Azure technology and features unavailable on the free tiers. The cost will naturally increase as the course progresses and we add more resources. So, it's progressively more costly. Also, during the course, we demo how to build 3 environments, which will increase the costs.

If you want to run and deploy the code while minimising the costs, we have some recommendations for you:

 - Take advantage of Azure Free offers:
   - [Azure free account](https://azure.microsoft.com/en-gb/pricing/purchase-options/azure-account?icid=azurefreeaccount)
   - [CosmosDB 30-day free offering](https://cosmos.azure.com/try/)
     - Add the `enableFreeTier: true` property to the bicep module.
   - [Microsoft Entra Free Trial](https://learn.microsoft.com/en-us/entra/fundamentals/try-microsoft-entra-suite)
 - Use a single environment. On the GitHub actions workflows, comment out the Jobs that deploy resources to Staging (stg) and Production (prd).
 - While you are not taking the course, delete the resource group. It's easy to recreate once you are back to it since we are using infrastructure as code.
 - Regularly review [Azure Cost Management reports](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/reporting-get-started).
 - Set up [budget alerts](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets?tabs=psbudget).

## Course Notes

### Infrastructure as Code

#### Download Azure CLI
https://learn.microsoft.com/en-us/cli/azure/

#### Log in to Azure
```bash
az login
```

#### Create Resource Group

```bash
az group create --name dometrain-urlshortener-dev --location westeurope
```

#### Deploy Bicep

#### What if
```bash
az deployment group what-if --resource-group dometrain-urlshortener-dev --template-file infrastructure/main.bicep
```

#### Deploy
```bash
az deployment group create --resource-group dometrain-urlshortener-dev --template-file infrastructure/main.bicep
```

#### Create a User for GH Actions

```bash
az ad sp create-for-rbac --name "GitHub-Actions-SP" \
                         --role contributor \
                         --scopes /subscriptions/89518450-6f9c-4039-8834-c5bab3ad3e92 \
                         --sdk-auth
```

#### Apply to Custom Contributor Role

```bash
az ad sp create-for-rbac --name "GitHub-Actions-SP" --role 'infra_deploy' --scopes /subscriptions/89518450-6f9c-4039-8834-c5bab3ad3e92 --sdk-auth
```

https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting?tabs=bicep

##### Configure a federated identity credential on an app

https://learn.microsoft.com/en-gb/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#configure-a-federated-identity-credential-on-an-app

### Get Azure Publish Profile

```bash
az webapp deployment list-publishing-profiles --name api-piza2nvlxc5jg --resource-group dometrain-urlshortener-dev --xml
```

### Get Static Web Apps Deployment Token

```bash
az staticwebapp secrets list --name web-app-piza2nvlxc5jg --query "properties.apiKey"
```


### Utilities

- Base62 converter: https://math.tools/calculator/base/10-62


### GitHub Actions

- https://learn.microsoft.com/en-us/azure/container-apps/tutorial-ci-cd-runners-jobs?tabs=bash&pivots=container-apps-jobs-self-hosted-ci-cd-azure-pipelines
- https://api.github.com/meta