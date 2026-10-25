# The service selects on the same labels the deployment selects on, by
# asking the deployment rather than restating them.
Matsuri.define :service, 'app-web' do
  let(:port_num) { 3000 }
  let(:selector) { deployment('app-web').match_labels }
end
