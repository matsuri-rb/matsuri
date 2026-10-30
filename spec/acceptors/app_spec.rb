# frozen_string_literal: true

require 'spec_helper'

# A hash-shaped acceptor: the stack-config artifact arrives whole, the
# declared lets are the accepted surface, and the artifact anchor owns
# the empty value.
RSpec.describe 'app acceptor' do
  let(:acceptor_class) { Matsuri::Registry.acceptor('app') }

  it 'answers declared reads from the artifact' do
    accepted = acceptor_class.new(name: 'app-feat', namespace: 'feat', log_level: 'debug')

    expect(accepted.instance_name).to eq 'app-feat'
    expect(accepted.namespace).to eq 'feat'
    expect(accepted.log_level).to eq 'debug'
  end

  it 'lands every read on its default over the empty value' do
    accepted = acceptor_class.new(nil)

    expect(accepted.instance_name).to be_nil
    expect(accepted.log_level).to eq 'info'
  end

  it 'passes unconsumed vocabulary in silence, raises on undeclared reads' do
    accepted = acceptor_class.new(name: 'app-feat', expires_at: '2026-11-15')

    expect(accepted.instance_name).to eq 'app-feat'
    expect { accepted.expires_at }.to raise_error(NoMethodError)
  end
end
