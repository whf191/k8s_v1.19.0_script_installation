#!/bin/bash
function  setting_k8s_china_repo(){
   echo "setting_k8s_china_repo"
   cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF
  yum -y install epel-release

}

function k8s_sysctl(){
echo "open_iptables_bridge"
  cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
vm.swappiness = 0
EOF

   sysctl --system

}

function disable_swap(){
  swapoff -a
  sed -ri 's/.*swap.*/#&/' /etc/fstab
}

function  kubeadmin_install() {
  yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
  yum install -y yum-utils
  yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  yum install docker-ce-19.03.12 docker-ce-cli-19.03.12 containerd.io
  yum install -y kubelet-1.19.0  
  yum install -y kubeadm-1.19.0
  yum install -y kubectl-1.19.0 
  systemctl enable --now docker
  systemctl enable --now kubelet

}


function docker_json(){

cat <<EOF >  /etc/docker/daemon.json
{
"insecure-registries": ["yharbor.xxx.cn","ydggharbor.xxx.cn"],
"registry-mirrors": ["https://fl791z1h.mirror.aliyuncs.com"],
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl restart docker
}


setting_k8s_china_repo
k8s_sysctl
disable_swap
kubeadmin_install
docker_json

#1.按需求修改kubeadmin-config-local-etcd.yaml的注释部分
#
#2.脚本运行结束，手动运行此命令,初始化k8s集群
#  kubeadm  init --config=2kubeadmin-config.yaml  --upload-certs
#3.初始成功后
#  kubectl apply -f kubeadmin-config-local-etcd.yaml
#  kubectl apply -f 2_custom-resources.yaml  #此处修改cidr的ip子网要和第一步的podSubnet子网相同