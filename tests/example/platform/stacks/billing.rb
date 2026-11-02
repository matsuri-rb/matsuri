# Classic delivery: matsuri owns every field and converges by
# client-side apply. One management promise, in this sequence.
Matsuri.define :stack, 'billing' do
  needs :config_map, 'cacerts'
  needs :config_map, 'billing-settings'
  needs :deployment, 'billing-web'
  needs :service,    'billing-web'
end
