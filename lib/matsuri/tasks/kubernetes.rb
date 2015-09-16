module Matsuri
  module Tasks
    class Kubernetes
      include Matsuri::Task

      let(:etcd_name)          { 'etcd' }
      let(:master_name)        { 'kubernetes_master' }
      let(:service_proxy_name) { 'kubernetes_proxy' }

      let(:etcd_image)         { "gcr.io/google_containers/etcd:#{etcd_ver}" }
      let(:hyperkube_image)    { "gcr.io/google_containers/hyperkube:#{hyperkube_ver}" }
      let(:etcd_ver)           { config.etcd_version || '2.0.12' }
      let(:hyperkube_ver)      { config.hyperkube_version || 'v1.0.6' }

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
    /hyperkube kubelet --containerized --hostname-override="#{config.master_addr}" --address="#{config.master_bind_addr}" --api-servers=#{config.api_servers} --config=/etc/kubernetes/manifests
END

      let(:service_proxy) { <<END }
-d --name #{service_proxy_name} --privileged=true --net=host #{hyperkube_image} /hyperkube proxy --master=#{config.master_url} --v=2
END
    end
  end
end
