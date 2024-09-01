# DEVOPS TOOLS ON AWS EC2


```bash
k create ns jenkins

k create sa jenkins -n jenkins

k create token jenkins -n jenkins

kubectl create rolebinding jenkins-admin-binding --clusterrole=admin --serviceaccount=jenkins:jenkins -n jenkins
```

