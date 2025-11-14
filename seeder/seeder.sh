#!/bin/bash
set -euo pipefail
echo "Logging in with admin user"
sleep 1
API_TOKEN=$(curl 'https://api.staging.01cloud.dev/user/login' -X POST -d '{"email":"admin@admin.com","password":"01cl0ud@2o2o"}' -s | jq .data.token |  sed -e 's/^"//' -e 's/"$//')
if [ "$API_TOKEN" == "null" ]
then
echo "Invalid authorization"
exit
elif [ "$API_TOKEN" == "" ]
then
echo "Server not running"
exit
fi
sleep 1
echo "Adding user quotas"
curl 'https://api.staging.01cloud.dev/admin/user/1/quotas' -X 'PUT' -H "Authorization: basic $API_TOKEN" -d '{"user_organization":10,"user_project":10}'
sleep 1
echo "Updating billing address"
curl 'https://api.staging.01cloud.dev/payment/paymentsetting' -X 'PUT' -H "Authorization: basic $API_TOKEN" -d '{"country":"Nepal","state":"Bagmati Province","city":"Kathmandu","street":"Kathmandu","postal_code":"00977","promocode":""}'
sleep 1
echo "Adding support group"
curl -X POST 'https://api.staging.01cloud.dev/ticket/group' -H "Authorization: basic $API_TOKEN" -d '{"title":"account","description":"account"}'
sleep 1
echo "Saving default config json file"
curl -X PUT 'https://api.staging.01cloud.dev/admin/file/setting.json' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/default-config.json)"
sleep 1
echo "Saving default config json file"
curl -X PUT 'https://api.staging.01cloud.dev/public/file/system-variable.json' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/system-variable.json)"
sleep 1
echo "Saving external logger config json file"
curl -X PUT 'https://api.staging.01cloud.dev/public/file/external-logger.json' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/external-logger.json)"
sleep 1
echo "Saving subscription config json file"
curl -X PUT 'https://api.staging.01cloud.dev/public/file/subscriptions.json' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/subscriptions.json)"
sleep 1
echo "Creating subscription"
curl  -X POST 'https://api.staging.01cloud.dev/subscription' -H "Authorization: basic $API_TOKEN" -d '{"name":"Basic Subscription","disk_space":10240,"memory":1024,"data_transfer":10240,"backups":5,"cores":1000,"apps":10,"price":1,"cron_job":10,"ci_build":10,"resource_list":{"configmaps":10,"persistentvolumeclaims":4,"pods":20,"replicationcontrollers":40,"secrets":20,"services":10,"loadbalancers":1,"gpu":0},"price_list":{"data_transfer":10,"load_balancer":10},"active":true}'
sleep 1
echo "Creating Organization Plan"
curl -X POST 'https://api.staging.01cloud.dev/organizationPlan' -H "Authorization: basic $API_TOKEN" -d '{"name":"Default","memory":10000,"cores":10000,"cluster":10,"price":1,"weight":0,"active":true,"attributes":"","no_of_user":100}'
sleep 1
echo "Creating resource"
curl 'https://api.staging.01cloud.dev/resource' -X POST -H "Authorization: basic $API_TOKEN" -d '{"name":"256MB","cores":200,"memory":256,"weight":1,"active":true,"attributes":""}'
sleep 1
echo "Adding wordpress plugin"
curl 'https://api.staging.01cloud.dev/plugin' -X POST -H "Authorization: basic $API_TOKEN" -d '{"name":"wordpress","description":"Plugin Description","attributes":"","active":true,"source_url":"https://wordpress.com","support_ci":false,"is_add_on":false,"min_cpu":100,"min_memory":128,"Categories":[],"add_ons":"","image":"https://s.w.org/style/images/about/WordPress-logotype-wmark.png"}'
sleep 1
echo "Adding wordpress plugin version"
curl -X POST 'https://api.staging.01cloud.dev/plugin-version' -H "Authorization: basic $API_TOKEN" --form "plugin_id=1" --form "version=15.2.40" --form 'change_logs=- update' --form "package=@seeder/wordpress-package-15.2.40.tgz"
sleep 1
echo "Updating registry list"
curl -X POST 'https://api.staging.01cloud.dev/registry-config' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/registry.json)"
sleep 1
echo "Adding Node plugin"
curl 'https://api.staging.01cloud.dev/plugin' -X POST -H "Authorization: basic $API_TOKEN" -d '{"name":"node","description":"Plugin Description","attributes":"","active":true,"source_url":"https://nodejs.org/en/","support_ci":true,"is_add_on":false,"min_cpu":100,"min_memory":128,"Categories":[],"add_ons":"","image":"https://api.01cloud.io/uploads/image/png/119369ad-a6c5-4f2e-9b58-2ebd05022292.png"}'
sleep 1
echo "Adding node plugin version"
curl -X POST 'https://api.staging.01cloud.dev/plugin-version' -H "Authorization: basic $API_TOKEN" --form "plugin_id=2" --form "version=1.0.0" --form 'change_logs=- update' --form "package=@seeder/node-package-1.0.0.tgz"
sleep 1
echo "Adding Docker plugin"
curl 'https://api.staging.01cloud.dev/plugin' -X POST -H "Authorization: basic $API_TOKEN" -d '{"name":"docker","description":"Plugin Description","attributes":"","active":true,"source_url":"https://hub.docker.com","support_ci":false,"is_add_on":false,"min_cpu":100,"min_memory":128,"Categories":[],"add_ons":"","image":"https://api.01cloud.io/uploads/image/png/66da5052-7e63-472f-bc02-bfba6eb09ba6.png"}'
sleep 1
echo "Adding docker plugin version"
curl -X POST 'https://api.staging.01cloud.dev/plugin-version' -H "Authorization: basic $API_TOKEN" --form "plugin_id=3" --form "version=1.0.0" --form 'change_logs=- update' --form "package=@seeder/docker-package-1.0.0.tgz"
sleep 1
echo "Creating dns"
ENV_FILE=".env"
# ---------------------------------------------------
# LOAD ENV VARIABLES
# ---------------------------------------------------
if [[ -f "$ENV_FILE" ]]; then
    echo "[INFO] Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "[WARN] $ENV_FILE not found"
fi

# ---------------------------------------------------
# VALIDATE REQUIRED VARIABLES
# ---------------------------------------------------
REQUIRED_VARS=(
    API_TOKEN PROVIDER NAME PROJECT_ID BASE_DOMAIN
    ORG_ID ACTIVE CREDS ZONE_ID TLS
)
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "[ERROR] Environment variable '$var' is missing."
        exit 1
    fi
done

curl "https://api.staging.01cloud.dev/dns" \
  -X POST \
  -H "Authorization: basic $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @<(cat <<EOF
{
  "provider": "$PROVIDER",
  "name": "$NAME",
  "project_id": "$PROJECT_ID",
  "base_domain": "$BASE_DOMAIN",
  "organization_id": $ORG_ID,
  "active": $ACTIVE,
  "credentials": "$CREDS",
  "zone_id": "$ZONE_ID",
  "tls": "$TLS"
}
EOF
)

sleep 1
echo "Creating registry"
curl -X POST 'https://api.staging.01cloud.dev/registry' -H "Authorization:basic $API_TOKEN" -d '{"name":"test","credentials":{"credentials":{"docker_registry_server":"hub.hem.xyz.np","project_name":"images","docker_username":"admin","docker_password":"pass"}},"provider":"custom"}'
sleep 1
echo "Importing local cluster"
curl 'https://api.staging.01cloud.dev/import-cluster' -X POST -H "Authorization: basic $API_TOKEN" --form "provider=default" --form "region=default" --form "name=default" --form "zone=default" --form "labels=default" --form "ArgoServerUrl=test"
sleep 1
echo "Updating dns"
curl 'https://api.staging.01cloud.dev/cluster/1' -X PUT -H "Authorization: basic $API_TOKEN" --form "dns_id=1" --form "image_registry_id=1"
sleep 1
echo "Updating package list"
curl -X POST 'https://api.staging.01cloud.dev/package-config' -H "Authorization:basic $API_TOKEN" -d "$(cat seeder/package_install.json)"
sleep 1
echo "Installing required packages"
curl 'https://api.staging.01cloud.dev/create-cluster/1/install-package' -X POST -H "Authorization: basic $API_TOKEN" -d '[{"chart":"zerone/cert-manager","name":"cert-manager","required_dns":true,"set":[]},{"chart":"zerone/contour","name":"contour","required_dns":true,"set":[],"needs":["dns-controller"]},{"chart":"zerone/dns-controller","name":"dns-controller","required_dns":true,"set":[]},{"chart":"zerone/prometheus-operator","name":"prometheus-operator","required_dns":true,"set":[],"needs":["dns-controller","contour"]}]'
sleep 5
echo "Completed dbseed procedures."
echo "Run './01cloud --help' for more options"
echo "Proceed to browser and open link https://console.staging.01cloud.dev , Happy browsing!!!"
