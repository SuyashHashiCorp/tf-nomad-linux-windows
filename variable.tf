##AWS instance Key Pair File
variable "key_pair" {
  type = map(string)
  default = {
    "key_name"   = ""
    "public_key"  = ""
  }
}

variable "key_path" {
  default = ""  #Key file name with absolute path should mention here.
}

variable "admin_password" {
  default = ""
}


#EC2
variable "ami" {
  default = "ami-04505e74c0741db8d"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "instance_name" {
  type    = list(string)
  default = ["Nomad-Linux-Server", "Nomad-Linux-Client"]
}

variable "private_ip" {
  type    = list(any)
  default = ["172.31.84.119", "172.31.84.120"]
}

variable "instance_count" {
  type    = number
  default = 2
}

#VPC
variable "subnet" {
  type    = string
  default = "" #Please make sure this subnet has accessibility to internet. Please use public subnet#
}

variable "sg_id" {
  type    = list(any)
  default = [""] ##Please insure this security group has Ports - 4646, 8500, 22 and ICMP enabled#
}

#UserScripts
variable "userscripts" {
  type    = list(any)
  default = ["nomad1_linux_data.sh", "client1_linux_data.sh"]
}

variable "scriptpaths" {
  type = string
  default = "/Users/suyash/Projects/tf-nomad-linux-windows/scripts/" #Update this path with your path where you cloned the git repository
}
