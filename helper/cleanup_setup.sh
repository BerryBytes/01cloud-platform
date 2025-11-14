kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
kubectl delete -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.47.0/release.yaml
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/cloud/deploy.yaml
helm uninstall openebs -n openebs
