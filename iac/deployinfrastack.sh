set -euo pipefail

./cleanup_role_assignments.sh

rg='acme-multi-rg'

# result=$(cat deployment_stack_output_sample.json)

# deploy common resources such as AKS and database server etc
result=$(az stack group create \
  --name 'acme-multi-common' \
  --resource-group $rg \
  --template-file 'templates/main.bicep' \
  --deny-settings-mode 'none' \
  --action-on-unmanage 'deleteResources' \
  --yes)

echo "Remember to restart keda-operator if needed..."
# kubectl rollout restart deploy keda-operator -n kube-system

# aksName=$(echo $result | jq -r '.outputs.aksName.value')
# mysqlServerName=$(echo $result | jq -r '.outputs.mysqlServerName.value')

# # get the identity used for keyvault access so we can add permissions to tenant keyvaults
# addonprofiles=$(az aks show -g $rg -n $aksName --query addonProfiles)
# AzureKeyvaulProviderClientId=$(echo $addonprofiles | jq -r '.azureKeyvaultSecretsProvider.identity.objectId')

# # deploy all tenants
# az stack group create \
#   --name 'acme-multi-tenantsss' \
#   --resource-group $rg \
#   --template-file 'templates/tenants.bicep' \
#   --deny-settings-mode 'none' \
#   --action-on-unmanage 'deleteResources' \
#   --parameters MySQLServerName=$mysqlServerName \
#   --parameters AzureKeyvaulProviderClientId=$AzureKeyvaulProviderClientId \
#   --yes