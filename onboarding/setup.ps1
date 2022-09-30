
# All the variables for the deployment
$azure_subscription_name = "AzureDev"
$azure_resource_group_name = "rg-defender-gcp"
$azure_location = "westeurope"

$gcp_project_id="airy-charge-364105"
$gcp_project_number="421932273897"

# Login and set correct contextes
az login -o table
az account set --subscription $azure_subscription_name -o table

gcloud auth login
gcloud config set project $gcp_project_id

# Validate
az group list -o table

gcloud projects list --format="json"
gcloud projects list --format="table(createTime.date('%Y-%m-%d'),name,projectNumber,projectId)"

