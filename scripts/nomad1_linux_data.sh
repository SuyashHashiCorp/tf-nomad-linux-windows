#!/usr/bin/env bash

#Change Hostname
sudo hostnamectl set-hostname "nomad-server"

echo "172.31.84.119  nomad-server" >> /etc/hosts
echo "172.31.84.120  nomad-client" >> /etc/hosts

export DEBIAN_FRONTEND=noninteractive

#Pre-reqs
apt-get update
apt-get install -y zip unzip wget apt-transport-https jq tree gnupg-agent net-tools

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
cat <<EOF > /etc/nomad.d/server.hcl
server {
    enabled = true
    license_path = "/etc/nomad.d/license.hclic"
    bootstrap_expect = 1
    raft_protocol = 3
}

#addresses {
#  http = "{{ GetDefaultInterfaces | attr \"address\" }}"  rpc  = "{{ GetAllInterfaces | include \"network\" \"172.0.0.0/24\" | attr \"address\" }}"  serf = "{{ GetAllInterfaces | include \"network\" \"172.0.0.0/24\" | attr \"address\" }}"}
ports {
    http = 4646
    rpc = 4647
    serf = 4648
}

datacenter = "dc1"
data_dir = "/opt/nomad"

acl {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"
}
EOF


#Writing License File
cat <<EOF > /etc/nomad.d/license.hclic
<use_your_Nomad_Enterprise_license_here>
EOF

sudo systemctl enable nomad
sudo systemctl start nomad

sleep 15

#Nomad ACL Bootstraping 
mkdir /home/ubuntu/ACL
touch /home/ubuntu/ACL/bootstrap.token
chmod -R 777 /home/ubuntu/ACL
nomad acl bootstrap -address http://172.31.84.119:4646 | tee /home/ubuntu/ACL/bootstrap.token


#Environment Variable Set
cat <<EOF > /etc/profile.d/nomad-bash-env.sh
export NOMAD_ADDR=http://172.31.84.119:4646
nomad -autocomplete-install
export NOMAD_TOKEN=$(awk '/Secret/ {print $4}' /home/ubuntu/ACL/bootstrap.token)
EOF


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
node_name = "nomad-server"
data_dir = "/opt/consul/"

server = true
license_path =  "/etc/consul.d/license.hclic"
bootstrap_expect = 1

ui_config {
    enabled = true
    }

bind_addr = "172.31.84.119"
client_addr = "0.0.0.0"

retry_join = ["172.31.84.119"]

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
