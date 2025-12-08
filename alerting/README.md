For implementing alert manager in the skaffold environemnt, follow the steps below:

## Step 1:
Add Prometheus repo in a separate namespace for monitoring

```helm repo add prometheus-community https://prometheus-community.github.io/helm-charts ```

```helm repo update```

```helm install prometheus prometheus-community/prometheus```

## Step 2:
Install gchat manager using helm chart

```helm repo add julb https://charts.julb.me ```

```helm install alert-manager julb/alertmanager-gchat-integration ```

## Step 3:
Verify if all the pods are running.

``` kubectl get pods -n monitoring ```

## Step 4:
Create configmap of prometheus alert-manager with the webhook url of gchat.

```
apiVersion: v1
data:
  alertmanager.yml: |
	global: {}
	receivers:
    	webhook_configs:
            	- url: 'http://gchat-alertmanager-gchat-integration:80/alerts?room=01cloudAlerts' ```
```

## Step 5:
Create configmap of prometheus-server with the necessary alerting rules.

### Step 6:
Convert the following to base 64.
```
[app.notification]
# Jinja2 custom template to print message to GChat.
custom_template_path = "/opt/alertmanager-gchat-integration/cm/notification-template-json.j2"
[app.room.01cloudAlerts]
notification_url = <google_chat_space_url>
```

## Step 7:
Use the converted base 64 code in the secrets of gchat manager in config.toml section

```
apiVersion: v1
data:
  config.toml: <base 64 config converted from step 6>>
kind: Secret
```
