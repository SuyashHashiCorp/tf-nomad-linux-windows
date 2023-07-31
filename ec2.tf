resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair["key_name"]
  public_key = var.key_pair["public_key"]
}


##Nomad Server and Client on Linux
resource "aws_instance" "instance" {
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = var.instance_type
  private_ip             = var.private_ip[count.index]
  key_name               = aws_key_pair.key_pair.key_name 
  subnet_id              = var.subnet
  vpc_security_group_ids = var.sg_id[*]
  tags = {
    Name = var.instance_name[count.index]
  }

  provisioner "file" {
    source      = "${var.scriptpaths}/${var.userscripts[count.index]}"
    destination = "/tmp/${var.userscripts[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/${var.userscripts[count.index]}",
      "sudo sh /tmp/${var.userscripts[count.index]}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = file(var.key_path)
    host        = self.public_ip
  }
}

##Nomad Client on Windows Server 2019
resource "aws_instance" "win_instance" {
  ami = "ami-00cd301dd78676b2d"
  instance_type          = "t2.medium"
  private_ip             = "172.31.84.113"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = var.subnet 
  vpc_security_group_ids = var.sg_id[*]
  get_password_data      = "true"
  user_data = <<-EOL
<powershell>
Set-NetFirewallRule -Name “WINRM-HTTP-In-TCP-PUBLIC” -RemoteAddress “Any”
#Create Directory for Nomad 
new-item -type directory -path C:\WorkSpace\Nomad\ -Force
new-item -type directory -path C:\WorkSpace\Nomad\data -Force

#Download Nomad 
Invoke-WebRequest -Uri https://releases.hashicorp.com/nomad/1.5.6+ent/nomad_1.5.6+ent_windows_amd64.zip -OutFile 'C:\WorkSpace\Nomad\nomad.zip'

#Extract File
Expand-Archive 'C:\WorkSpace\Nomad\nomad.zip' -DestinationPath 'C:\WorkSpace\Nomad\'

#Nomad Configuration File
New-Item C:\WorkSpace\Nomad\client.hcl

Set-Content "C:\WorkSpace\Nomad\client.hcl" 'name = "nomad-client-windows"'
Add-Content "C:\WorkSpace\Nomad\client.hcl" 'bind_addr = "0.0.0.0"

advertise {
  http = "172.31.84.113"
  rpc  = "172.31.84.113"
  serf = "172.31.84.113"
}

consul {
  address = "172.31.84.111:8500"
}

client {
  enabled = true
  options {
  }
}

plugin "docker" {
  config {
    allow_caps = ["ALL"]
    endpoint = "npipe:////./pipe/docker_engine"
    pull_activity_timeout = "30m"
    volumes {
     enabled = true
    }
    gc {
      image       = true
      image_delay = "0"
      container   = true

      dangling_containers {
        enabled        = true
        dry_run        = false
        period         = "5m"
        creation_grace = "5m"
      }
    }
  }
}'

#Create Service for Nomad
#New-Service -Name "Nomad" -BinaryPathName "C:\WorkSpace\Nomad\nomad.exe agent -config C:\WorkSpace\Nomad\client.hcl"

New-Service -Name Nomad -BinaryPathName "C:\WorkSpace\Nomad\nomad.exe agent -config=C:\WorkSpace\Nomad\" -DisplayName Nomad -Description "Client Mode Hashicorp Nomad Service https://www.nomadproject.io/" -StartupType "Automatic" 
#-Credential $Credential

#Start Nomad Services
Start-Service -Name "Nomad"

</powershell>
EOL
  tags = {
    Name = "Nomad-Win"
  }
  connection {
    host = self.public_ip
    type = "winrm"
    port = 5985
    https = false
    insecure = true
    timeout = "5m"
    user = "Administrator"
    password = "${rsadecrypt(self.password_data, file(var.key_path))}"
  }
  depends_on = [
    aws_instance.instance
  ]
}
