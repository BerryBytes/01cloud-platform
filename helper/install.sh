if [ $(whoami) == "root" ]
then
    ./01cloud setup $1 $2
    ./01cloud host remove
    ./01cloud host
    ./01cloud dbrun $2
    while true
    do
        ready=`kubectl --kubeconfig $KUBECONFIG get pod -n 01cloud-staging -l app.kubernetes.io/instance=staging-mongodb | grep staging-mongodb | awk '{print $2}'`
        if [ "$ready" == "1/1" ]
        then
            sleep 10
            break
        fi
        echo "Mongodb status :: $ready, sleeping for 10 seconds..."
        sleep 10
    done
    # kubectl --kubeconfig $KUBECONFIG rollout restart deployment ingress-nginx-controller -n ingress-nginx
    sleep 1
    ./01cloud run
    while true
    do
        ready=`kubectl get --kubeconfig $KUBECONFIG pod -n 01cloud-staging -l app=01cloud-api | grep 01cloud-api | awk '{print $2}'`
        if [ "$ready" == "1/1" ]
        then
            sleep 10
            break
        fi
        echo "API Pod status :: $ready, sleeping for 10 seconds..."
        sleep 10
    done
    while true
    do
        ready=`kubectl get --kubeconfig $KUBECONFIG pod -n 01cloud-staging -l app=01cloud-payments | grep 01cloud-payments | awk '{print $2}'`
        if [ "$ready" == "1/1" ]
        then
            sleep 10
            break
        fi
        echo "Payment Pod status :: $ready, sleeping for 10 seconds..."
        sleep 10
    done
    sleep 10
    bash seeder/seeder.sh
else
    echo "Need sudo permission to run this command"
fi
