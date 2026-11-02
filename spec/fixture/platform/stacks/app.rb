# frozen_string_literal: true

# One management promise: the app's bulkheads, the service fronting them,
# and the settings they share converge as one act, in this sequence.
Matsuri.define :stack, 'app' do
  needs :config_map, 'app-settings'
  needs :deployment, 'app-web'
  needs :deployment, 'app-web-streams'
  needs :deployment, 'app-worker-general'
  needs :service,    'app-web'
end
