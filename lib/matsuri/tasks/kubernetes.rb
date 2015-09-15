module Matsuri
  module Tasks
    class Kubernetes
      include Matsuri::Task

      let(:etcd_name)          { 'etcd' }
      let(:master_name)        { 'kubernetes_master' }
      let(:service_proxy_name) { 'kubernetes_proxy' }

      def up!
        docker_run! etcd
        docker_run! master
        docker_run! service_proxy
        docker! 'ps'
      end

      def down!
        docker! "kill #{service_proxy_name}"
        docker! "kill #{master_name}"
        docker! "kill #{etcd_name}"
        docker! "rm #{service_proxy_name}"
        docker! "rm #{master_name}"
        docker! "rm #{etcd_name}"
      end

      let(:etcd) { <<END }
--net=host -d --name #{etcd_name} gcr.io/google_containers/etcd:2.0.12 /usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data
END

      let(:master) { <<END }
    --name #{master_name } \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/dev:/dev \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --privileged=true \
    -d \
    gcr.io/google_containers/hyperkube:v1.0.1 \
    /hyperkube kubelet --containerized --hostname-override="127.0.0.1" --address="0.0.0.0" --api-servers=http://localhost:8080 --config=/etc/kubernetes/manifests
END

      let(:service_proxy) { <<END }
-d --name #{service_proxy_name} --net=host --privileged gcr.io/google_containers/hyperkube:v1.0.1 /hyperkube proxy --master=http://127.0.0.1:8080 --v=2
END
    end
  end
end
