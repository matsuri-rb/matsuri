# Billing is stateless and reschedules cheaply, so it rides the
# preemptible pool. The image tracks the converge positional
# (default: the image_tag acceptor's default).
Matsuri.define :pod, 'billing' do
  include Acme::Pods::Healthcheck
  include Acme::Pods::CACerts
  include Acme::Nodes::Preemptible

  let(:labels)      { { 'app' => 'billing' } }
  let(:tolerations) { [preemptible_toleration] }

  let(:cpu_limit) { '500m' }
  let(:mem_limit) { '512Mi' }

  let(:volumes) { [cacerts_volume] }
  let(:container) do
    {
      name:           'billing',
      image:          "registry.acme.io/billing:#{image_tag}",
      readinessProbe: readiness_probe,
      resources:      resources,
      volumeMounts:   [cacerts_mount]
    }
  end
end
