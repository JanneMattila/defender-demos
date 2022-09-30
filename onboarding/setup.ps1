
# All the variables for the deployment
$gcp_project_id = "airy-charge-364105"
$gcp_project_number = "421932273897"

$azure_subscription_name = "AzureDev"
$azure_resource_group_name = "rg-defender-gcp"
$azure_location = "westeurope"

$azure_connector_name = "connector-$gcp_project_id"
$connector_identity_name = "microsoft defender for cloud" # The GCP workload identity federation pool id

# Login and set correct contextes
az login -o table
az account set --subscription $azure_subscription_name -o table
$azure_subscription_id = $(az account show --query id -o tsv)

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

$gcp_project_parent = $($gcp_project_json | jq .parent.id -r)
$gcp_project_labels = $($gcp_project_json | jq .labels)
$gcp_project_labels_json = $gcp_project_labels | ConvertFrom-Json
$gcp_project_labels_json.company_code
$gcp_project_labels_json.company_finance_code

# Update project labels to resource group
az group update --name $azure_resource_group_name `
    --set tags.gcp_company_code=$($gcp_project_labels_json.company_code) `
    --set tags.gcp_company_finance_code=$($gcp_project_labels_json.company_finance_code)

# Deploy GCP connector script in GCP Console
# https://learn.microsoft.com/en-us/rest/api/defenderforcloud/security-connectors

$body = ConvertTo-Json @{
    "location"   = "$azure_location"
    "tags"       = @{
        "gcp_company_code"         = $gcp_project_labels_json.company_code
        "gcp_company_finance_code" = $gcp_project_labels_json.company_finance_code
    }
    "properties" = @{
        "environmentName"     = "GCP"
        "environmentData"     = @{
            "environmentType"    = "GcpProject"
            "organizationalData" = @{
                "organizationMembershipType" = "Member"
                "parentHierarchyId"          = "$gcp_project_parent"
            }
            "projectDetails"     = @{
                "projectId"              = "$gcp_project_id"
                "projectNumber"          = "$gcp_project_number"
                "workloadIdentityPoolId" = "$connector_identity_name"
            }
        }
        "hierarchyIdentifier" = "$gcp_project_number"
        "offerings"           = @(@{
                "offeringType" = "CspmMonitorGcp"
            }
            @{
                "offeringType" = "DefenderForServersGcp"
            }
            @{
                "offeringType"                    = "DefenderForContainersGcp"
                "auditLogsAutoProvisioningFlag"   = $true
                "policyAgentAutoProvisioningFlag" = $true
            })
    }
} -Depth 50
$body
$body > body.json

az rest `
    --method put `
    --url  "https://management.azure.com/subscriptions/$azure_subscription_id/resourceGroups/$azure_resource_group_name/providers/Microsoft.Security/securityConnectors/$azure_connector_name`?api-version=2021-12-01-preview" `
    --body `@body.json