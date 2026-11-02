# frozen_string_literal: true

# The stack-config surface the app stack coordinates on. The artifact
# anchor owns the empty value: no artifact means every read lands on its
# default.
Matsuri.define :acceptor, 'app' do
  let(:artifact) { options || {} }

  let(:instance_name) { artifact[:name] }
  let(:namespace)     { artifact[:namespace] }
  let(:log_level)     { artifact[:log_level] || 'info' }
end
