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

![image](https://github.com/SuyashHashiCorp/tf-nomad-linux-windows/assets/92308220/ea6bf6b5-f48b-4fdd-8f2b-ecf18cb88e5e)


5. Security Group Settings - Please create or update your security group as per the below table -

![image](https://github.com/SuyashHashiCorp/tf-nomad-linux-windows/assets/92308220/5ae8ded9-c75c-4431-8724-1277da26a076)


6. Update the values as per the below table -

![image](https://github.com/SuyashHashiCorp/tf-nomad-linux-windows/assets/92308220/3b79ef0d-e464-4858-b2ab-2b1ab66e2bed)


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
