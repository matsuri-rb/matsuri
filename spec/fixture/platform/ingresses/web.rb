# frozen_string_literal: true

Matsuri.define :ingress, 'web' do
  let(:ingress_class) { 'nginx' }

  let(:rules) do
    [http_rule(host: 'app.example.com', paths: path('/', service: 'app-web', port: 80))]
  end

  let(:tls) do
    [{ hosts: ['app.example.com'], secretName: 'app-web-tls' }]
  end
end
