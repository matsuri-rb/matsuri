# frozen_string_literal: true

Matsuri.define :config_map, 'app-settings' do
  let(:data) do
    {
      'LOG_LEVEL'    => 'info',
      'WORKER_QUEUE' => 'default'
    }
  end
end
