# Get the External IP of the LoadBalancer service
ENVOY_IP=$(kubectl get svc "$LB_SVC_NAME" -n envoy-gateway-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$ENVOY_IP" ]; then
    echo "Envoy external IP not found yet. Waiting for Envoy to be ready."
else
    echo "Envoy External IP is :: $ENVOY_IP"
    # Define hostnames to append/remove from /etc/hosts
    HTTPROUTE_HOSTS=(
        "api.staging.01cloud.dev"
        "terminal.staging.01cloud.dev"
        "ws-gateway.staging.01cloud.dev"
        "admin.staging.01cloud.dev"
        "api-gateway.staging.01cloud.dev"
        "console.staging.01cloud.dev"
    )

    if [ "${1:-}" == "remove" ]; then
        # Remove all hosts from /etc/hosts
        for host in "${HTTPROUTE_HOSTS[@]}"; do
            if grep -q "[[:space:]]$host[[:space:]]" /etc/hosts; then
                sudo sed -i "/[[:space:]]$host[[:space:]]/d" /etc/hosts
                echo "Removed $host from /etc/hosts"
            fi
        done
    else
        # Construct single line entry with ENVOY_IP
        HOSTS_LINE="$ENVOY_IP"
        for host in "${HTTPROUTE_HOSTS[@]}"; do
            HOSTS_LINE+=" $host"
        done

        # Append the new line without removing existing entries
        printf "\n%s\n" "$HOSTS_LINE" | sudo tee -a /etc/hosts > /dev/null
        echo "Added hosts -> $HOSTS_LINE"
    fi
fi
