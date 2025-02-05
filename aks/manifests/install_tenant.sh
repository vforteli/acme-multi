if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tenantname>"
    exit 1
fi

tenant_name=$1

aks_name=tkjfse-aks
rg_name=acme-multi-rg
backend_sp_name="$1-backend-sp"
worker_sp_name="$1-worker-sp"
keda_sp_name=tkjfse-keda-sp
sb_namespace_endpoint="$1-sbn.servicebus.windows.net"

azureKeyvaultSecretsProviderClientId=$(az aks show -g $rg_name -n $aks_name --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
echo "Found keyvault provider clientId: $azureKeyvaultSecretsProviderClientId"

backendClientId=$(az identity show -g $rg_name -n $backend_sp_name --query 'clientId' -o tsv)
echo "Found backend clientId: $backendClientId"

workerClientId=$(az identity show -g $rg_name -n $worker_sp_name --query 'clientId' -o tsv)
echo "Found worker clientId: $workerClientId"

kedaClientId=$(az identity show -g $rg_name -n $keda_sp_name --query 'clientId' -o tsv)
echo "Found keda clientId: $kedaClientId"

# This is all a bit daft, but premium SKU service bus with private endpoints costs 10 times more than standard...
serviceBusIpAddress=$(dig acmeoverseas-sbn.servicebus.windows.net +short | awk 'NR==2')
echo "Found ip $serviceBusIpAddress for $sb_namespace_endpoint"

echo "Upgrading tenant..." 
helm upgrade \
    --install app-$tenant_name someapp \
    --namespace $tenant_name \
    --create-namespace \
    -f ./someapp/values.yaml \
    -f ./tenants/$tenant_name-values.yaml \
    --set kedaClientId=$kedaClientId \
    --set azurekeyvaultsecretsproviderClientId=$azureKeyvaultSecretsProviderClientId \
    --set tenant.backendClientId=$backendClientId \
    --set tenant.workerClientId=$workerClientId \
    --set tenant.serviceBusIpAddress=$serviceBusIpAddress \