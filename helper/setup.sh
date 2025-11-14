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
echo "Installing nginx ingress controller"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
while true
do
  loadbalancerIP=`kubectl get svc ingress-nginx-controller -n ingress-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  if [ ! -z "$loadbalancerIP" ]
  then
    break
  fi
  echo "Loadbalancer IP :: $loadbalancerIP, sleeping for 10 seconds..."
  sleep 10
done
while true
    do
        ready=`kubectl get pod -n ingress-nginx -l app.kubernetes.io/component=controller | grep controller | awk '{print $2}'`
        if [ "$ready" == "1/1" ]
        then
            sleep 10
            break
        fi
        echo "Nginx status :: $ready, sleeping for 10 seconds..."
        sleep 10
    done
echo "Completed setup, You IP is $loadbalancerIP"
echo "Run './01cloud --help' for more options"