k8s 1.10.0一键安装脚本
操作系统要求
  centos7

主节点
执行 k8s_master.sh

从节点
执行 k8s_node.sh
注意： 节点join注册后，手动执行下这条命令
echo 'KUBELET_KUBEADM_ARGS=--cgroup-driver=systemd --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice  --cni-bin-dir=/opt/cni/bin --cni-conf-dir=/etc/cni/net.d --network-plugin=cni' > /var/lib/kubelet/kubeadm-flags.env
