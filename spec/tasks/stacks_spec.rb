# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Tasks::Stacks do
  describe '.seed' do
    it 'derives the seeded and declared payloads from the resource' do
      deployment = Matsuri::Registry.fetch_or_load(:deployment, 'web').new
      seed = instance_double(described_class::Seed, run!: true)
      expect(described_class::Seed).to receive(:new)
        .with(hash_including(seeded:        deployment.to_yaml,
                             declared:      deployment.applied_to_yaml,
                             resource_type: 'deployment',
                             name:          'web',
                             namespace:     'specs',
                             description:   'deployment/web',
                             field_manager: 'matsuri'))
        .and_return(seed)
      described_class.seed(deployment)
    end
  end
end
