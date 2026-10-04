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