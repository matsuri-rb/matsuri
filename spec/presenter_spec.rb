# frozen_string_literal: true

require 'spec_helper'

# A presenter definition fills holes with lets; this example concern mirrors
# how value-shaped built-ins will ship — machinery plus a declared hole.
module PresenterSpec
  module ExampleSeedImage
    extend Concern

    included do
      let(:image) { fail Matsuri::UndefinedLet, 'Must define let(:image)' }
    end

    def transform(manifest)
      update_each(manifest.get(:spec, :template, :spec, :containers), [:image]) { image }
      manifest
    end
  end
end

# Pins the framework-owned boundary: self.call = new.call, #call makes the
# one copy and delegates to #transform, the bare presenter is the identity
# element, and definitions resolve through the registry.
RSpec.describe Matsuri::Presenter do
  let(:manifest) do
    Map.new(kind: 'Deployment', metadata: { name: 'web' }, spec: { replicas: 1 })
  end

  let(:workload) do
    Map.new(spec: { template: { spec: { containers: [{ name: 'app', image: 'app:old' }] } } })
  end

  describe 'the boundary' do
    it 'the bare presenter is the identity, modulo the boundary copy' do
      presented = described_class.call(manifest)
      expect(presented).to eq manifest
      expect(presented).not_to equal manifest
    end

    it 'never mutates the input manifest' do
      presented = Matsuri::Registry.presenter('team-label').call(manifest)
      expect(presented.get(:metadata, :labels, :team)).to eq 'platform'
      expect(manifest.get(:metadata, :labels)).to be_nil
    end

    it 'copies at the boundary for plain hash input too' do
      input = { kind: 'Deployment', metadata: { name: 'web' } }
      presented = Matsuri::Registry.presenter('team-label').call(input)
      expect(presented.get(:metadata, :labels, :team)).to eq 'platform'
      expect(input[:metadata].key?(:labels)).to be false
    end
  end

  describe 'registry resolution' do
    it 'resolves a definition from presenters_path as a Presenter subclass' do
      expect(Matsuri::Registry.presenter('team-label').ancestors).to include described_class
    end

    it 'coerces a name member end-to-end through Callable' do
      pipeline = Matsuri::Transform::Callable.new(['team-label'])
      expect(pipeline.call(manifest).get(:metadata, :labels, :team)).to eq 'platform'
    end
  end

  describe 'concern holes filled by definition lets' do
    it 'a definition let defines exactly what the value is' do
      seeded = Class.new(described_class) do
        include PresenterSpec::ExampleSeedImage
        let(:image) { 'app:v2' }
      end
      expect(seeded.call(workload).get(:spec, :template, :spec, :containers, 0, :image)).to eq 'app:v2'
    end

    it 'an unfilled hole fails fast at first read' do
      unfilled = Class.new(described_class) { include PresenterSpec::ExampleSeedImage }
      expect { unfilled.call(workload) }.to raise_error(Matsuri::UndefinedLet, /image/)
    end

    it 'a helper can close a declaration-time value into an anonymous definition' do
      seed_image_presenter = ->(image_value) do
        Class.new(described_class) do
          include PresenterSpec::ExampleSeedImage
          let(:image) { image_value }
        end
      end
      presented = seed_image_presenter.('app:v3').call(workload)
      expect(presented.get(:spec, :template, :spec, :containers, 0, :image)).to eq 'app:v3'
    end
  end
end
