#!/bin/bash
git rev-parse --is-inside-work-tree
if [ $? != 0 ]
then
echo error: this command must be run inside the folder which is part of github repo ; 
exit 1
fi
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/create.sh -o create.sh
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/rollout.yaml -o rollout.yaml
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/service.yaml -o service.yaml
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/services.txt -o services.txt
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/template.yaml -o template.yaml

curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/secret.yaml -o secret.yaml
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/instructions.txt -o instructions.txt
curl https://raw.githubusercontent.com/gopaljayanthi/testArgoProj/main/bg-template/application.yaml -o application.yaml

git add -A
git commit -m "adding templates"
git push

echo Please read instructions.txt in folder before running create.sh with required arguments

