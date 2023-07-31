#!/usr/bin/env bash

#Change Hostname
sudo hostnamectl set-hostname "nomad-client"

echo "172.31.84.119  nomad-server" >> /etc/hosts
echo "172.31.84.120  nomad-client" >> /etc/hosts

export DEBIAN_FRONTEND=noninteractive

#Pre-reqs
apt-get update
apt-get install -y zip unzip wget apt-transport-https jq tree gnupg-agent net-tools

##CONSUL

#Hashicorp apt repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#Update the apt-get
sudo apt-get update

#Install consul manually
export CONSUL_VERSION="1.15.3+ent"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/bin/

#Create directories
mkdir --parents /etc/consul.d
sudo chmod 755 /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo touch /etc/consul.d/consul.env
chmod 640 /etc/consul.d/consul.hcl

#Consul Service File Configuration
cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
Type=notify
#User=consul
#Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


#Consul Configuration (HCL)
cat <<EOF > /etc/consul.d/consul.hcl
node_name = "nomad-client"
data_dir = "/opt/consul/"
server = false
license_path = "/etc/consul.d/license.hclic"
bind_addr = "172.31.84.120"
client_addr = "0.0.0.0"

retry_join = ["172.31.84.119"]

ports {
  grpc = 8502
}

connect {
  enabled = true
}
EOF


#Consul Env Variable
cat <<EOF > /etc/profile.d/consul-bash-env.sh
consul -autocomplete-install
EOF


#Writing License File
cat <<EOF >/etc/consul.d/license.hclic
<use_your_Consul_Enterprise_license_here>
EOF


#Enable Consul Services
sudo systemctl enable consul
sudo systemctl start consul


# DOCKER #
#Install docker
apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

#Add auto completion for docker
curl -fsSL https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
curl -fsSL https://github.com/docker/docker-ce/blob/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

#Facilitate nomad access to docker
usermod -G docker -a ubuntu


# ENVOY #
curl -fsSL https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
sudo cp `func-e which` /usr/local/bin


# ###CNI plug in
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v0.9.1.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf cni-plugins.tgz


#Install nomad manually
export NOMAD_SER_VERSION="1.5.6+ent"
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_SER_VERSION}/nomad_${NOMAD_SER_VERSION}_linux_amd64.zip
unzip nomad_${NOMAD_SER_VERSION}_linux_amd64.zip
sudo chown root:root nomad
sudo mv nomad /usr/local/bin/


#Create directories
mkdir -p /opt/nomad
mkdir -p /etc/nomad.d

chmod 755 /opt/nomad
chmod 755 /etc/nomad.d


##Nomad Service File Configuration
cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d/ -bind=0.0.0.0
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF


#Nomad Configuration
cat <<EOF > /etc/nomad.d/client.hcl
datacenter = "dc1"
data_dir = "/opt/nomad"
enable_debug = true
client {
  enabled = true
  server_join {
    retry_join = ["172.31.84.119"]
  }
}

#addresses {
#  http = "{{ GetDefaultInterfaces | attr \"address\" }}"  rpc  = "{{ GetAllInterfaces | include \"network\" \"172.0.0.0/24\" | attr \"address\" }}"  serf = "{{ GetAllInterfaces | include \"network\" \"172.0.0.0/24\" | attr \"address\" }}"}
ports {
    http = 4646
    rpc = 4647
    serf = 4648
}
acl {
  enabled = true
}
plugin "raw_exec" {
  config {
    enabled = true
  }
}
consul {
    address = "127.0.0.1:8500"
}
EOF


#Enable Nomad service
sudo systemctl enable nomad
sudo systemctl start nomad


#Environment Variable Set
cat <<EOF > /etc/profile.d/nomad-bash-env.sh
export NOMAD_ADDR=http://172.31.84.119:4646
nomad -autocomplete-install
EOF
