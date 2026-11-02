Matsuri.define :service, 'checkout-web' do
  let(:port_num) { 8000 }
  let(:selector) { deployment('checkout-web').match_labels }
end
