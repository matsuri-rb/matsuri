# Acme's internal CA bundle, mounted by Acme::Pods::CACerts. A real
# repo would source this from the org's certificate distribution.
Matsuri.define :config_map, 'cacerts' do
  let(:data) do
    {
      'acme-root.pem' => "-----BEGIN CERTIFICATE-----\nEXAMPLE\n-----END CERTIFICATE-----\n"
    }
  end
end
