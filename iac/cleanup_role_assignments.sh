set -euo pipefail

rg='acme-multi-rg'

echo "Searching for orphaned role assignments..."
orphaned_assignments=$(az role assignment list --query "[?principalName=='']" --all -o json)

if [[ $orphaned_assignments == "[]" ]]; then
    echo "No orphaned role assignments found"
    exit 0
fi

echo "Removing orphaned role assignments"

for role_assignment_id in $(echo "$orphaned_assignments" | jq -r '.[].id'); do
    echo "Removing role assignment: $role_assignment_id"
    az role assignment delete --ids "$role_assignment_id"   
done

echo "Done..."
