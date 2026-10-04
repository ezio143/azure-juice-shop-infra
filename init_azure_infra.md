# initial manual step to create resources in azure to store terraform state -->

#   local setup - create azure resource group and storage account
az login
az account set --subscription <your-subscription-id>

LOCATION=centralindia          # pick the region you used for Juice Shop
RG=rg-tfstate
SA=sttfstate${RANDOM}${RANDOM} # must be globally unique, lowercase alphanumeric, 3-24 chars (sttfstate127751717)
CONTAINER=tfstate

az group create -n $RG -l $LOCATION

az storage account create -n $SA -g $RG -l $LOCATION \
  --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false

## versioning + soft delete so a bad apply or deletion is recoverable
az storage account blob-service-properties update \
  --account-name $SA -g $RG \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 7

## control-plane container creation, so it doesn't depend on your data-plane role yet
az storage container-rm create --storage-account $SA -g $RG -n $CONTAINER

echo $SA   # note this nazame, you'll need it in providers.tf and in Step 2


## assign yourself data-plan access (RBAC for local runs)
ME=$(az ad signed-in-user show --query id -o tsv)
SA_ID=$(az storage account show -n $SA -g $RG --query id -o tsv)

az role assignment create \
  --assignee-object-id $ME --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope $SA_ID

#   ====================================================================

## setting up Identities in git and federated credentials

GH_OWNER=<your-github-username>
GH_REPO=<your-infra-repo-name>
SUB=$(az account show --query id -o tsv)
TENANT=$(az account show --query tenantId -o tsv)
SA_ID=$(az storage account show -n $SA -g $RG --query id -o tsv)

## Plan Azure APP (PRs only, read-mostly)
PLAN_APP=$(az ad app create --display-name gh-tf-plan --query appId -o tsv)
az ad sp create --id $PLAN_APP

az ad app federated-credential create --id $PLAN_APP --parameters "{
  \"name\": \"gh-pull-request\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:$GH_OWNER/$GH_REPO:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

az role assignment create --assignee $PLAN_APP --role Reader \
  --scope /subscriptions/$SUB
az role assignment create --assignee $PLAN_APP --role "Storage Blob Data Contributor" \
  --scope $SA_ID

## Apply Azure APP (main branch via production environment only)

GH_OWNER=<your-github-username>
GH_REPO=<your-infra-repo-name>
RG=rg-tfstate                      # your single resource group
SA=<your-storage-account-name>

SUB=$(az account show --query id -o tsv)
TENANT=$(az account show --query tenantId -o tsv)
SA_ID=$(az storage account show -n $SA -g $RG --query id -o tsv)
RG_ID=$(az group show -n $RG --query id -o tsv)

APPLY_APP=$(az ad app create --display-name gh-tf-apply --query appId -o tsv)
az ad sp create --id $APPLY_APP

az ad app federated-credential create --id $APPLY_APP --parameters "{
  \"name\": \"gh-env-production\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:$GH_OWNER/$GH_REPO:environment:production\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

<!-- # remove the subscription-wide Contributor if you created it earlier (ignore errors if not) -->
az role assignment delete --assignee $APPLY_APP --role Contributor \
  --scope /subscriptions/$SUB

<!-- # Contributor on the RG only -->
az role assignment create --assignee $APPLY_APP --role Contributor --scope $RG_ID

<!-- # state access through Entra auth -->
az role assignment create --assignee $APPLY_APP \
  --role "Storage Blob Data Contributor" --scope $SA_ID

## setup the Azue App ids in Github
gh variable set AZURE_APPLY_CLIENT_ID --body "$APPLY_APP"

<!-- # Verify -->
az ad app federated-credential list --id $APPLY_APP -o table
az role assignment list --assignee $APPLY_APP --all -o table

<!-- you must reference the manually created resource group in terraform source code -->
data "azurerm_resource_group" "main" {
  name = "rg-tfstate"
}