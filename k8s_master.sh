#!/usr/bin/env bash
cd `dirname $0`
#
#k8s 1.10.0版本 master一键安装.
#
#系统要求centos7

#常用变量配置
k8s_name="k8s version 1.10.0"

#start 基础环境准备
function disable_firewalld_selinux(){
   echo "disable firewalld and selinux"
   systemctl  disable firewalld
   systemctl stop firewalld
   setenforce 0
   sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux

}

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

function open_iptables_bridge(){
echo "open_iptables_bridge"
  cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

   sysctl --system

}

function disable_swap(){
  echo "disable_swap  and into is /etc/rc.local"
  swapoff -a
  echo 'swapoff -a ' >>/etc/rc.local
  chmod +x /etc/rc.local
}

##end基础环境准备

function install_kubeadm_docker(){
 echo "install is kubeadmin v1.10.0  and docker "
 yum install -y kubelet-1.11.0 kubeadm-1.11.0 kubectl-1.11.0 kubernetes-cni wget net-tools
 systemctl enable kubelet && systemctl start kubelet
 yum install  docker -y
 systemctl enable docker && systemctl start docker
}

function pull_docker(){
  echo "pull is  k8s 1.10.0  images"
  images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
   etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
   k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
   for imageName in ${images[@]} ; do
       docker pull keveon/$imageName
       docker tag keveon/$imageName k8s.gcr.io/$imageName
       docker rmi keveon/$imageName

   done
   docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1

}

function kubeadm_init(){
   echo "kubeadm init  begin"
   kubeadm init --kubernetes-version=v1.11.0 --pod-network-cidr=10.244.0.0/16
   echo "kubeadm init end"
   mkdir -p $HOME/.kube
   /bin/cp  /etc/kubernetes/admin.conf $HOME/.kube/config
   chown $(id -u):$(id -g) $HOME/.kube/config
}

function change_kubelet_config(){
   echo "change kubelet  config"
   echo 'KUBELET_KUBEADM_ARGS=--cgroup-driver=systemd --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice  --cni-bin-dir=/opt/cni/bin --cni-conf-dir=/etc/cni/net.d --network-plugin=cni' > /var/lib/kubelet/kubeadm-flags.env

}

function install_network_add-on(){
   echo "install is Flannel network add-on"
   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
   if [ $? -eq 0 ]
   then
      echo "Flannel is ok"
   else
      wget https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
      kubectl apply -f kube-flannel.yml
   fi

}

function install_kubernetes-dashboard(){
  echo "install kubernetes-dashboard.. via is port 30090"
  cd kubernetes-dashboard
  for i in `ls *.yaml`
  do
     kubectl  apply -f $i
  done

}

function install_finish(){
 echo "____________________________"
 echo "_____________________________"
 echo "$k8s_name is install finish"
 echo "you is need  run: \n  kubectl get pods --all-namespaces "


}


function run(){
disable_firewalld_selinux
setting_k8s_china_repo
open_iptables_bridge
disable_swap
install_kubeadm_docker
pull_docker
kubeadm_init
change_kubelet_config
install_network_add-on
install_kubernetes-dashboard
install_finish
}

run