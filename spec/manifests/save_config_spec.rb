# frozen_string_literal: true

require 'spec_helper'

# save_config resolves most-specific-first: a definition's own let, the
# owning stack's declaration, then the repo-wide Platform setting
# (default true). Normal apply path only — it feeds create/recreate's
# --save-config flag and nothing else.
RSpec.describe 'save_config resolution' do
  let(:deployment) { Matsuri::Registry.deployment('app-web').new }

  after { Matsuri::Platform.save_config = true }

  it 'defaults true from the platform' do
    expect(deployment.save_config).to be true
  end

  it 'reads a repo-wide platform override' do
    Matsuri::Platform.save_config = false
    expect(deployment.save_config).to be false
  end

  it 'a stack declaration overrides the platform, riding to resource members' do
    stack = Matsuri.define(:stack, 'save-config-stack') do
      save_config false
      needs :deployment, 'app-web'
    end

    expect(stack.new.members.first.save_config).to be false
  end

  it 'never crosses to nested stacks' do
    stack = Matsuri.define(:stack, 'save-config-nested') do
      save_config false
      needs :deployment, 'app-web'
    end

    expect(stack.new.dep_options(:stack)).not_to have_key(:save_config)
  end

  it 'a resource let overrides the stack declaration' do
    Matsuri.define(:deployment, 'save-config-own', inherits: 'app-web') do
      let(:save_config) { true }
    end
    stack = Matsuri.define(:stack, 'save-config-resource-wins') do
      save_config false
      needs :deployment, 'save-config-own'
    end

    expect(stack.new.members.first.save_config).to be true
  end
end
