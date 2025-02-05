if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tenantname>"
    exit 1
fi

tenant_name=$1

helm uninstall \
    app-$tenant_name \
    --namespace $tenant_name