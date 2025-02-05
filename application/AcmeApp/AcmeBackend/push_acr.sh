set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tag>"
    exit 1
fi

tag=$1


nerdctl build --tag $tag .
nerdctl tag $tag tkjfseacr.azurecr.io/$tag
nerdctl push tkjfseacr.azurecr.io/$tag