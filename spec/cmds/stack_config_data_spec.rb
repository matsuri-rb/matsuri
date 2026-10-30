# frozen_string_literal: true

require 'spec_helper'

# The CLI owns the boundary mapping: --stack-config= names a path, the
# stack's :config collection expects data. No flag is the empty value; a
# flag with a bad path fails loudly, never falls back.
RSpec.describe 'stack_config_data' do
  let(:cmd) { Class.new { include Matsuri::Cmd }.new }

  def stack_config_data(opt)
    cmd.send(:stack_config_data, opt)
  end

  it 'answers the empty value when no flag was given' do
    expect(stack_config_data({})).to be_nil
  end

  it 'loads the artifact whole, with indifferent access' do
    data = stack_config_data(stack_config: File.join(FIXTURE_ROOT, 'stack-config.yaml'))

    expect(data[:name]).to eq 'app-feat-checkout'
    expect(data[:log_level]).to eq 'debug'
    expect(data[:expires_at]).to eq '2026-11-15'
  end

  it 'fails loudly on a bad path' do
    expect { stack_config_data(stack_config: 'no-such-file.yaml') }
      .to raise_error(SystemExit).and output(/stack-config not found/).to_stdout
  end
end
