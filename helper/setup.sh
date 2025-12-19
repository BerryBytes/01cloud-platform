SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATEWAY_DIR="$SCRIPT_DIR/../gateway"

if [ "$1" != "remote" ]
then
  bash helper/setup_metallb.sh
fi
if [ "$2" == "rwx" ]
then
helm install openebs openebs/openebs -n openebs --create-namespace \
  --set ndm.enabled=false \
  --set ndmOperator.enabled=false \
  --set localprovisioner.enabled=false  \
  --set nfs-provisioner.enabled=true
fi
echo "Installing tekton"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v1.4.0/release.yaml
sleep 5

echo "Installing Gateway API CRDs..."
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml || echo " Warning: Failed to install Gateway API CRDs"

echo "Installing KrakenD Helm chart..."
{
    helm upgrade --install krakend "$GATEWAY_DIR/krakend" -n krakend --create-namespace --wait --timeout 10m
} || echo " Warning: KrakenD Helm install timed out, continuing..."

echo "Installing Envoy Helm chart..."
{
    helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version v1.4.6 -n envoy-gateway-system  --create-namespace --wait --timeout 10m --skip-crds
} || echo " Warning: Envoy Helm install timed out, continuing..."

echo "Applying Gateway resources..."
for f in "$GATEWAY_DIR/gateway.yaml"; do
    kubectl apply -f "$f" || echo " Warning: Failed to apply $f"
done
# --- Wait for Envoy LoadBalancer service and get External IP (MetalLB) ---
echo "Waiting for Envoy LoadBalancer service to get an external IP..."

while true; do
    LB_SVC_NAME=$(kubectl get svc -n envoy-gateway-system \
        --field-selector spec.type=LoadBalancer \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [ -n "$LB_SVC_NAME" ]; then
        ENVOY_IP=$(kubectl get svc "$LB_SVC_NAME" -n envoy-gateway-system \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$ENVOY_IP" ]; then
            echo "Envoy LoadBalancer is ready: $LB_SVC_NAME -> $ENVOY_IP"
            break
        fi
    fi

    echo "Waiting for LoadBalancer IP from MetalLB..."
    sleep 5
done

sleep 15

echo "Run './01cloud --help' for more options"
