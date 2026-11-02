# frozen_string_literal: true

require 'spec_helper'

# Pins the monoid laws: identity left/right, associativity on the nose,
# structural homomorphism via operand member-list concat, and the no-flatten
# representation (a composite member stays one member).
RSpec.describe Matsuri::Transform::Callable do
  let(:manifest) { Map.new(spec: { replicas: 1 }) }

  let(:bump) do
    described_class.new(label: 'bump') { |m| m.set([:spec, :replicas], m.get(:spec, :replicas) + 1) }
  end

  let(:tag) do
    described_class.new(label: 'tag') { |m| m.set([:metadata, :tag], 'x') }
  end

  let(:identity) { described_class.new }

  describe 'identity' do
    it 'passes the manifest through untouched' do
      expect(identity.call(manifest)).to equal manifest
    end

    it 'is the left and right identity of +' do
      expect((identity + bump).members).to eq bump.members
      expect((bump + identity).members).to eq bump.members
    end
  end

  describe '+' do
    it 'is associative on the nose' do
      expect(((bump + tag) + bump).members).to eq (bump + (tag + bump)).members
    end

    it 'concatenates operand member lists into a new instance' do
      composed = bump + tag
      expect(composed.members).to eq bump.members + tag.members
      expect(composed).not_to equal bump
    end

    it 'composition then call equals call then call' do
      expect((bump + bump).call(manifest).get(:spec, :replicas))
        .to eq bump.call(bump.call(Map.new(spec: { replicas: 1 }))).get(:spec, :replicas)
    end
  end

  describe 'composite members' do
    it 'never flattens: a composite member stays one member' do
      composite = described_class.new([bump, tag], label: 'bundle')
      outer     = described_class.new([composite, bump])
      expect(outer.members.length).to eq 2
      expect(outer.members.first).to equal composite
    end

    it 'carries the label as trace metadata' do
      expect(bump.label).to eq 'bump'
      expect(described_class.new([bump], label: 'bundle').label).to eq 'bundle'
    end

    it 'calls through nested composites in declaration order' do
      composite = described_class.new([bump, tag])
      result    = described_class.new([composite, bump]).call(manifest)
      expect(result.get(:spec, :replicas)).to eq 3
      expect(result.get(:metadata, :tag)).to eq 'x'
    end
  end

  describe 'coercion' do
    it 'takes anything #call-able as-is' do
      double_up = ->(m) { m.set([:spec, :replicas], m.get(:spec, :replicas) * 2) }
      expect(described_class.new([double_up]).call(manifest).get(:spec, :replicas)).to eq 2
    end

    it 'fails fast on a member that cannot transform' do
      expect { described_class.new([42]) }.to raise_error(ArgumentError, /42/)
    end

    it 'fails fast on members and block together' do
      expect { described_class.new([bump]) { |m| m } }.to raise_error(ArgumentError)
    end
  end
end
