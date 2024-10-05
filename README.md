# DEVOPS TOOLS ON AWS EC2

## Initilize the cluster with in AWS

### AWS

```bash
# Configure the credentials
aws configure

# Check the credentials
aws sts get-caller-identity
```

### Clone the repo
```bash
git clone https://github.com/mialeevs/devops_tools_aws_k8s.git

cd devops_tools_aws_k8s
```

### Initilize the cluster
```bash
./create.sh
```

### Delete the cluster
```bash
./delete.sh
```
