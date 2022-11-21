#!/bin/bash
mydir=$1 # a folder an application and a namespace will be created using this
bns=$2 # baseline namespace
pns=$3 # preview namespace
isdns=$4 # isd namespace
instructions=' error: you need to be connected to the kubernetes cluster to get this script to work '
usage='error: Usage: ./create.sh directoryname baseline-namesapce canary-namespace'

if [ -z $mydir ]; then echo $usage; exit 1; fi
if [ -z $pns ]; then  echo $usage; exit 1; fi
if [ -z $bns ]; then  echo $usage; exit 1; fi
if [ -z $isdns ]; then  echo $usage; exit 1; fi

kubectl version

if [ $? != 0 ]
then
echo $instructions; 
exit 1
fi

git rev-parse --is-inside-work-tree
if [ $? != 0 ]
then
echo this command must be run inside the folder which is part of github repo which was used to deploy to argocd; 
exit 1
fi

echo creating folder $mydir
mkdir -p $mydir
rm -rf $mydir/*.yaml
rm -rf $mydir/*.sh
cp *.yaml $mydir
cp services.txt $mydir
cd $mydir 

curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/trigger-analysis.sh -o trigger-analysis.sh

echo creating rollout

sed -i "s/BASELINE-NAMESPACE/$bns/" rollout.yaml
sed -i "s/PREVIEW-NAMESPACE/$pns/" rollout.yaml

echo creating secret

isdhost=$( kubectl -n $isdns get ing oes-ui-ingress -o jsonpath='{.spec.rules[0].host}')
 if [ -z $isdhost ]; then  echo isd ingress not found, are you sure isd in installed in $isdns; exit 1; fi

sed -i "s#GATE-URL#$isdhost#" secret.yaml

echo creating analysis template

kubectl -n "$bns" get deploy -o name  | grep deployment | sed 's/\// /' | awk '{print $2}' > deploys.txt
 if [ ! -s deploys.txt ]; then echo error: no deployments found in namespace $bns; exit 1 ; fi

kubectl -n "$pns" get deploy -o name  | grep deployment | sed 's/\// /' | awk '{print $2}' > previewdeploys.txt
 if [ ! -s previewdeploys.txt ]; then echo error: no deployments found in namespace $pns; exit 1 ; fi

while read line 
 do 
echo adding service $line to template
sed "s/SERVICENAME/$line/g" services.txt >> template.yaml 
done < deploys.txt

argocdhost=$( kubectl -n $isdns get ing argocd-ingress -o jsonpath='{.spec.rules[0].host}')

repourl=$(git config --get remote.origin.url)

echo application yaml from template
sed -i "s/APP-NAME/$mydir/" application.yaml
sed -i "s#GIT-REPO#$repourl#" application.yaml

echo cleaning up
rm -rf *.txt

echo Successfully created application, secret, service, rollout and template yaml files
echo
echo please review template.yaml and remove any unneeded services from the services section
echo
echo  add/commit/push  $mydir to your github repo and create an argocd application from the argocd ui at $argocdhost

git add rollout.yaml
git add secret.yaml
git add service.yaml
git add template.yaml
git add trigger-analysis.sh

git commit -m "added the application $mydir"
git push

echo creating application in argocd
kubectl -n $isdns apply -f application.yaml

rm -rf application.yaml



echo login to argocd host $argocdhost and look for application $mydir and sync it

echo 'to trigger analysis run go to the folder $mydir in your local github repo and run ./trigger-analysis.sh <namespace where this rollout was deployed> '

echo please review template.yaml in $mydirand remove any unneeded services from the services section then add/commit/push to github