Matsuri.define :config_map, 'billing-settings' do
  let(:data) do
    {
      'LOG_LEVEL'      => 'info',
      'INVOICE_BUCKET' => 'acme-invoices'
    }
  end
end
