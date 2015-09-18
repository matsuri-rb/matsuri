module Matsuri
  module Tasks
    class Kubernetes
      include Matsuri::Task

      let(:etcd_name)          { 'etcd' }
      let(:master_name)        { 'kubernetes_master' }
      let(:service_proxy_name) { 'kubernetes_proxy' }

      let(:etcd_image)         { "gcr.io/google_containers/etcd:#{etcd_ver}" }
      let(:hyperkube_image)    { "gcr.io/google_containers/hyperkube:#{hyperkube_ver}" }
      let(:kube2sky_image)     { "gcr.io/google_containers/kube2sky:#{kube2dns_ver}" }
      let(:skydns_image)       { "gcr.io/google_containers/skydns:#{skydns_ver}" }
      let(:etcd_ver)           { config.etcd_version || '2.0.12' }
      let(:hyperkube_ver)      { config.hyperkube_version || 'v1.0.6' }
      let(:kube2dns_ver)       { config.kube2dns_version || '1.11' }
      let(:skydns_ver)         { config.skydns_version || '2015-03-11-001' }

      # Setup flanneld on the host
      def generate_setup!
        puts(<<END)
#!/bin/bash
set -xe

echo 'Bootstrapping with etcd and flanneld'

# Bring up docker-bootstrap
#docker -d -H unix:///var/run/docker-bootstrap.sock -p /var/run/docker-bootstrap.pid --iptables=false --ip-masq=false --bridge=none --graph=/var/lib/docker-bootstrap 2> /var/log/docker-bootstrap.log 1> /dev/null &

# Ubuntu
stop docker || true
start docker-bootstrap || true
docker -H unix:///var/run/docker-bootstrap.sock rm -f $(docker -H unix:///var/run/docker-bootstrap.sock ps -qa) || true

# Bring up etcd on docker-bootstrap
docker -H unix:///var/run/docker-bootstrap.sock run --net=host --name etcd -d gcr.io/google_containers/etcd:2.0.12 /usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data
sleep 3
docker -H unix:///var/run/docker-bootstrap.sock run --net=host gcr.io/google_containers/etcd:2.0.12 etcdctl set /coreos.com/network/config '{ "Network": "#{config.kubernetes_cidr}" }'


# Bring up flanneld on docker-bootstrap
docker -H unix:///var/run/docker-bootstrap.sock run -d --name flanneld --net=host --privileged -v /dev/net:/dev/net quay.io/coreos/flannel:0.5.0

echo 'Bringing docker0 down. You may need to install bridge-utils'
/sbin/ifconfig docker0 down || true
brctl delbr docker0 || true

sleep 3
echo
echo 'Modify /etc/default/docker and add the following:'
echo '. /etc/flannel.env'
echo '--bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}'
echo 'then restart docker daemon'
docker -H unix:///var/run/docker-bootstrap.sock exec flanneld cat /run/flannel/subnet.env > /etc/flannel.env
END
      end

      def up!
        #docker_run! etcd
        docker_run! master
        docker_run! service_proxy
        docker! 'ps'
        puts "Wait for a bit and then start up dns"
        #puts "Waiting for api service to come up"
        #sleep 15
        #dns_up!
      end

      def down!
        docker! "kill #{service_proxy_name}"
        docker! "kill #{master_name}"
        docker! "kill #{etcd_name}"
        docker! "rm #{service_proxy_name}"
        docker! "rm #{master_name}"
        docker! "rm #{etcd_name}"
      end

      def dns_up!
        Matsuri::AddOns::DNS.start!
      end

      let(:etcd) { <<END }
        --net=host -d --name #{etcd_name} #{etcd_image} /usr/local/bin/etcd --addr=#{config.etcd_addr} --bind-addr=#{config.etcd_bind_addr} --data-dir=/var/etcd/data
END

      let(:master) { <<END }
    --name #{master_name} \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/dev:/dev \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --privileged=true \
    -d \
    #{hyperkube_image} \
    /hyperkube kubelet \
      --containerized --hostname-override=#{config.master_addr} --address=#{config.master_bind_addr} \
      --api-servers=#{config.api_servers} --config=/etc/kubernetes/manifests-multi \
      --cluster-dns=#{config.cluster_dns} --cluster_domain=#{config.cluster_domain}  --enable_server --v=2
END

      let(:master_try) { <<END }
    --name #{master_name} \
    --net=host \
    --privileged=true \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock \
    #{hyperkube_image} \
    /hyperkube kubelet \
      --containerized --hostname-override=#{config.master_addr} --address=#{config.master_bind_addr} \
      --api-servers=#{config.api_servers} --config=/etc/kubernetes/manifests--multi \
      --cluster-dns=#{config.cluster_dns} --cluster_domain=#{config.cluster_domain}  --enable_server --v=2
END

      let(:service_proxy) { <<END }
-d --name #{service_proxy_name} --privileged=true --net=host #{hyperkube_image} /hyperkube proxy --master=#{config.master_url} --v=2
END

    end
  end
end
