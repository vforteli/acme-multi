# Something something multi tenant AKS + something

## Current steps for setup

```shell
# Deploy infra
./deployinfrastack.sh

# Create subnet for privatelinks in aks vnet
# Create privatelink manually for blob and dfs in new privatelink subnet with static ip
# Fix IPs in values.yaml if needed

# Deploy a tenant
./install_tenant acmeoverseas
```

## Todo

- [x] network isolation
- [x] network policies tweaking
- [x] nginx ingress
- [ ] appgw ingress
- [x] secrets.. csi + keyvault pipelines etc
- [x] populate identity for keyvault rbac
- [-] dynamically add environments from some central single source of truth?
- [x] multiple deployments and services, test connectivity, and policies
- [x] wif testing with datalake
- [ ] create users in db, add secrets to kv etc.. maybe test this with postgres instead
- [x] privatelink to db... do we want this or a service endpoint? costs a bit
- [x] privatelink setup automagically? if its worth it..
- [x] start adding stuff to env... not secrets but endpoints etc
- [ ] internal everything
- [x] keda and scaledjobs
- [ ] variable and parameter cleanup
- ... more

## Tenants

- Acme Overseas acmeoverseas
- Acme Drilling acmedrilling
- Acme MegaCorp acmemegacorp

## Helm

```shell
# Installing a tenant in AKS using script with tenant name as parameter, eg:
./install_tenant acmeoverseas
./install_tenant acmedrilling

# Uninstall a tenant
./uninstall_tenant acmeoverseas
./uninstall_tenant acmedrilling
```
