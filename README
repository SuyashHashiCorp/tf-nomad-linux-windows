# tf-nomad-linux-windows

# Terraform Code and Scripts to Automate Nomad Setup using Linux and Windows Client Nodes via Terraform (Compatible for Mac with M1 Chip)

## Prerequisites

1. AWS Account.
2. 3 EC2 Instances With the below Specification - 
 A. For Linux Machine - 
   a. Instance Type = "t2.medium"
   b. AMI = "ami-04505e74c0741db8d"

 B. For Windows Server 2019 Machine -
   a. Instance Type = "t2.medium"
   b. AMI = "ami-00cd301dd78676b2d"

3. Public Subnet with CIDR - 172.31.0.0/16 (This is being used for private IPs allocation as per point-4 and POD CIDR Range in Nomad Cluster).

4. Private IPs will be assigned as below - 

![alt text](file:///Users/suyash/Desktop/Screenshot%202023-07-31%20at%2011.49.36%20AM.png)

Nomad-Linux-Server - 172.31.84.119
Nomad-Linux-Client - 172.31.84.120
Nomad-Windows-Client - 172.31.84.113

5. Security Group Settings - Please create or update your security group as per the below table -

![alt text](file:///Users/suyash/Desktop/Screenshot%202023-07-31%20at%2012.12.22%20PM.png)

6. Update the values as per the below table -

![alt text](file:///Users/suyash/Desktop/Screenshot%202023-07-31%20at%2012.40.29%20PM.png)

## Usage/Examples

To provision the cluster, execute the following commands.

```shell
git clone https://github.com/SuyashHashiCorp/terraform-k8s.git
cd terraform-k8s
terraform init
terraform plan
terraform apply
```

## To destroy the cluster, 

```shell
terraform destroy -auto-approve
```

## To restart the cluster,

```shell
terraform apply -auto-approve
```
