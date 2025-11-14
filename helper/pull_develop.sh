#!/bin/bash
cd ../01cloud
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-admin
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-api
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-core
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-tekton-ci
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-tekton-provision
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-notification
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-payments
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-support
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-monitoring
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-backup
git checkout . && git checkout develop && git pull origin develop
cd ../01cloud-external-secret
git checkout . && git checkout develop && git pull origin develop

echo "Pulling process completed"
