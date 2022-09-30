
# All the variables for the deployment
$azure_subscription_name = "AzureDev"
$azure_resource_group_name = "rg-defender-gcp"
$azure_location = "westeurope"

$gcp_project_id = "airy-charge-364105"
$gcp_project_number = "421932273897"

# Login and set correct contextes
az login -o table
az account set --subscription $azure_subscription_name -o table

gcloud auth login
gcloud config set project $gcp_project_id

# Validate
az group list -o table

gcloud projects list --format="json"
gcloud projects list --format="table(createTime.date('%Y-%m-%d'),name,projectNumber,projectId)"

# Create resource group
az group create -l $azure_location -n $azure_resource_group_name -o table

# Get project labels
$gcp_project_json = $(gcloud projects describe $gcp_project_id --format="json")
$gcp_project_json | jq .

$gcp_project_labels = $($gcp_project_json | jq .labels)
$gcp_project_labels_json = $gcp_project_labels | ConvertFrom-Json
$gcp_project_labels_json.company_code
$gcp_project_labels_json.company_finance_code

# Update project labels to resource group
az group update --name $azure_resource_group_name `
    --set tags.gcp_company_code=$($gcp_project_labels_json.company_code) `
    --set tags.gcp_company_finance_code=$($gcp_project_labels_json.company_finance_code)
