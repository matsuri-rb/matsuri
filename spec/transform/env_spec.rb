# frozen_string_literal: true

require 'spec_helper'

# Pins the array <-> map isomorphism laws: the round trip preserves entries
# and order, carries valueFrom intact, and updates through the map side keep
# existing positions while new keys append at the end.
RSpec.describe Matsuri::Transform::Env do
  subject(:env) { described_class }

  let(:entries) do
    [
      Map.new(name: 'A', value: '1'),
      Map.new(name: 'B', valueFrom: { secretKeyRef: { name: 'creds', key: 'token' } }),
      Map.new(name: 'C', value: '3')
    ]
  end

  describe 'round trip' do
    it 'preserves entries and order through the isomorphism' do
      round_tripped = env.expand_env(env.env_to_map(entries)).map { |e| Map.new(e) }
      expect(round_tripped).to eq entries
    end

    it 'compacts duplicate names to the last write' do
      duplicated = [Map.new(name: 'A', value: '1'), Map.new(name: 'A', value: '2')]
      expect(env.expand_env(env.env_to_map(duplicated))).to eq [{ name: 'A', value: '2' }]
    end
  end

  describe '.env_to_map' do
    it 'keys entries by name and carries valueFrom intact' do
      mapped = env.env_to_map(entries)
      expect(mapped['A']).to eq '1'
      expect(mapped.get('B', :secretKeyRef, :key)).to eq 'token'
    end
  end

  describe '.update_kv' do
    it 'updates an existing key in place, preserving order' do
      updated = env.update_kv(entries, 'A', '9')
      expect(updated.map { |e| e[:name] }).to eq %w[A B C]
      expect(updated.first[:value]).to eq '9'
    end

    it 'appends a new key at the end' do
      updated = env.update_kv(entries, 'D', '4')
      expect(updated.map { |e| e[:name] }).to eq %w[A B C D]
    end
  end
end
