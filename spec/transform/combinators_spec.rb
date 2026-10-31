# frozen_string_literal: true

require 'spec_helper'

# Pins the combinator laws: identity on non-match (the manifest comes back
# untouched, same object), wrap-of-identity (matching changes nothing when
# the element is the identity), and criteria as the conjunction of declared
# constraints. The registry-name case covers coercion end-to-end.
RSpec.describe Matsuri::Transform::Combinators do
  include Matsuri::Transform::Combinators::Helpers

  let(:deployment) do
    Map.new(kind: 'Deployment', metadata: { name: 'web', namespace: 'specs' }, spec: { replicas: 1 })
  end

  let(:service) { Map.new(kind: 'Service', metadata: { name: 'web' }) }

  let(:bump) do
    Matsuri::Transform::Callable.new(label: 'bump') { |m| m.set([:spec, :replicas], 2) }
  end

  it 'is the identity on a non-matching manifest' do
    expect(match_deployments(bump).call(service)).to equal service
    expect(service.get(:spec)).to be_nil
  end

  it 'applies the element on a matching manifest' do
    expect(match_deployments(bump).call(deployment).get(:spec, :replicas)).to eq 2
  end

  it 'wrapping the identity changes nothing on a match' do
    identity = Matsuri::Transform::Callable.new
    expect(match_kind('Deployment', identity).call(deployment)).to equal deployment
  end

  describe 'criteria' do
    it 'is the conjunction of the declared constraints' do
      applied = match({ kind: 'Deployment', name: 'web', namespace: 'specs' }, bump).call(deployment)
      expect(applied.get(:spec, :replicas)).to eq 2
    end

    it 'does not match when any declared constraint misses' do
      expect(match({ kind: 'Deployment', name: 'other' }, bump).call(deployment)).to equal deployment
    end

    it 'rejects unknown criteria keys' do
      expect { match({ kine: 'Deployment' }, bump) }.to raise_error(ArgumentError, /kine/)
    end
  end

  describe 'element coercion' do
    it 'fails fast on an element that cannot transform' do
      expect { match_kind('Deployment', 42) }.to raise_error(ArgumentError, /42/)
    end

    it 'resolves a registry name through to the presenter' do
      presented = match_deployments('team-label').call(deployment)
      expect(presented.get(:metadata, :labels, :team)).to eq 'platform'
      expect(deployment.get(:metadata, :labels)).to be_nil
    end
  end
end
