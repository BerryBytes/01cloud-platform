network=`kubectl --kubeconfig $KUBECONFIG get svc ingress-nginx-controller -n ingress-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
if [ -z "$network" ]
then
    echo "External ip not found"
    exit
fi
echo "External IP is :: $network"
host=`cat /etc/hosts | grep "console.staging.01cloud.dev"`
if [ "$1" == "remove" ]
then
    if [ -z "$host" ]
    then
        echo "Hostname not found"
        echo "Enter ./01cloud --help for more options"
    else
        sed "/$host/d" /etc/hosts -i
        echo "Hostname removed successfully"
    fi
else
    if [ -z "$host" ]
    then
        if [ $(whoami) == "root" ]
        then
            echo "Setting up host name"
            printf "$network console.staging.01cloud.dev api.staging.01cloud.dev admin.staging.01cloud.dev terminal.staging.01cloud.dev" >> /etc/hosts
            sleep 2
            echo "Hostname added successfully"
        else
            echo "Need sudo permission for running host command"
        fi
    else
        echo "Hostname already exist"
        echo "$host"
    fi
fi
