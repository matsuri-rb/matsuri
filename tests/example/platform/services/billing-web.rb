# Selects on the same labels the deployment selects on, by asking the
# deployment rather than restating them.
Matsuri.define :service, 'billing-web' do
  let(:port_num) { 8000 }
  let(:selector) { deployment('billing-web').match_labels }
end
