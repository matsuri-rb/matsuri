module Matsuri
  module AddOns
    class DNS
      DEPS = [%w(pod kube-dns-v10), %w(rc kube-dns-v10), %w(service kube-dns)].freeze

      def self.register!
        Matsuri::Registry.register :pod,       'kube-dns-v10', DNSPod
        Matsuri::Registry.register :rc,        'kube-dns-v10', DNSReplicator
        Matsuri::Registry.register :service,   'kube-dns',     DNSService
      end

      def self.show!(_)
        register!
        DEPS.each do |(type, name)|
          resource = Matsuri::Registry.fetch_or_load(type, name).new
          puts resource.to_yaml
        end
      end

      def self.start!
        register!
        Matsuri::Registry.rc('kube-dns-v10').new.start!
        Matsuri::Registry.service('kube-dns').new.start!
        #Matsuri::Registry.endpoints('kube-dns').new.start!
      end

      def self.stop!
        register!
        Matsuri::Registry.rc('kube-dns-v10').new.stop!
        Matsuri::Registry.service('kube-dns').new.stop!
        #Matsuri::Registry.endpoints('kube-dns').new.start!
      end

      class DNSPod < Matsuri::Kubernetes::Pod
        # See: https://github.com/kubernetes/kubernetes/blob/v1.0.6/cluster/addons/dns/skydns-rc.yaml.in
        let(:name) { 'kube-dns-v10' }
        let(:labels) do
          {
            'k8s-app' => 'kube-dns',
            'version' => 'v10',
            'kubernetes.io/cluster-service' => 'true'
          }
        end

        let(:dev_address) { platform.dev_addr || config.dev_addr }

        # Set dnsPolicy to 'Default' so we don't use cluster dns
        let(:spec) { { containers: containers, volumes: volumes, dnsPolicy: 'Default' } }
        let(:containers) { [etcd, kube2sky, skydns, healthz] }
        let(:volumes)    { [empty_dir_volume('etcd-storage')] }

        let(:etcd) do
          {
            name: 'etcd',
            image: 'gcr.io/google_containers/etcd:2.0.9',
            resources: { limits: { cpu: '100m', memory: '50Mi' }, requests: { cpu: '100m', memory: '50Mi' } },
            command: %w(
              /usr/local/bin/etcd
                -data-dir /var/etcd/data
                -listen-client-urls http://127.0.0.1:2379,http://127.0.0.1:4001
                -advertise-client-urls http://127.0.0.1:2379,http://127.0.0.1:4001
                -initial-cluster-token
                skydns-etcd
              ),
            volumeMounts: [mount('etcd-storage', '/var/etcd/data')]
          }
        end

        let(:kube2sky) do
          {
            name: 'kube2sky',
            image: 'gcr.io/google_containers/kube2sky:1.12',
            resources: { limits: { cpu: '100m', memory: '50Mi' }, requests: { cpu: '100m', memory: '50Mi' } },
            args: ["-domain=#{config.cluster_domain}", "-kube_master_url=http://#{dev_address}:8080"]
          }
        end

        let(:skydns) do
          {
            name: 'skydns',
            image: 'gcr.io/google_containers/skydns:2015-10-13-8c72f8c',
            resources: { limits: { cpu: '100m', memory: '50Mi' }, requests: { cpu: '100m', memory: '50Mi' } },
            args: ['-machines=http://localhost:4001', '-addr=0.0.0.0:53',"-domain=#{config.cluster_domain}"],
            ports: [port(53, name: 'dns', protocol: 'UDP'), port(53, name: 'dns-tcp')],
            livenessProbe:
              {
                httpGet: { path: '/healthz', port: 8080, scheme: 'HTTP' },
                initialDelaySeconds: 30,
                timeoutSeconds: 5
              }
          }
        end

        let(:healthz) do
          {
            name: 'healthz',
            image: 'gcr.io/google_containers/exechealthz:1.0',
            resources: { limits: { cpu: '10m', memory: '20Mi' } },
            args: ["-cmd=nslookup kubernetes.default.svc.#{config.cluster_domain} localhost >/dev/null", '-port=8080'],
            ports: [port(8080)]
          }
        end
      end

      class DNSReplicator < Matsuri::Kubernetes::ReplicationController
        let(:name) { 'kube-dns-v10' }
        let(:namespace) { 'kube-system' }
        let(:labels) do
          {
            'k8s-app' => 'kube-dns',
            'version' => 'v10',
            'kubernetes.io/cluster-service' => 'true'
          }
        end

        let(:replicas) { 1 }
        let(:pod_name) { 'kube-dns-v10' }

        let(:selector) do
          {
            'k8s-app' => 'kube-dns',
            'version' => 'v10'
          }
        end
      end

      class DNSService < Matsuri::Kubernetes::Service
        let(:name)       { 'kube-dns' }
        let(:namespace)  { 'kube-system' }
        let(:labels)     do
          {
            'k8s-app' => 'kube-dns',
            'kubernetes.io/cluster-service' => 'true',
            'kubernetes.io/name'            => "KubeDNS"
          }
        end

        let(:spec)       { { selector: selector, clusterIP: cluster_ip, ports: ports } }

        let(:cluster_ip) { config.cluster_dns }
        let(:selector)   { { 'k8s-app' => 'kube-dns' } }
        let(:ports)      { [dns, dns_tcp] }
        let(:dns)        { port 53, protocol: :UDP, name: 'dns' }
        let(:dns_tcp)    { port 53, protocol: :TCP, name: 'dns-tcp' }
      end
    end
  end
end
