# frozen_string_literal: true

require 'spec_helper'

# The algebra is pure data-in, data-out. These specs pin op behavior plus the
# laws the strata promise: zero-point on empty carriers, strict variants that
# raise instead of logging, and a carrier that stays plain data throughout.
RSpec.describe Matsuri::Transform::Algebra do
  subject(:algebra) { described_class }

  let(:spec) do
    Map.new(
      containers: [
        { name: 'app',     image: 'app:1', env: [{ name: 'A', value: '1' }] },
        { name: 'sidecar', image: 'sidecar:1' }
      ],
      volumes: []
    )
  end

  describe '.update_in' do
    it 'updates a deeply nested value with the transform function' do
      algebra.update_in(spec, [:containers, 0, :image]) { |image| image.sub(':1', ':2') }
      expect(spec.get(:containers, 0, :image)).to eq 'app:2'
    end
  end

  describe '.append_to' do
    it 'appends an entry at the path' do
      algebra.append_to(spec, [:volumes], name: 'data')
      expect(spec.get(:volumes).map { |v| v['name'] }).to eq ['data']
    end

    it 'raises PathNotFound when nothing exists at the path' do
      expect { algebra.append_to(spec, [:tolerations], key: 'x') }
        .to raise_error(Matsuri::Transform::PathNotFound, /tolerations/)
    end
  end

  describe '.update_each' do
    it 'updates the path within each element' do
      updated = algebra.update_each(spec.get(:containers), [:image]) { |image| "registry/#{image}" }
      expect(updated.map { |c| c['image'] }).to eq ['registry/app:1', 'registry/sidecar:1']
    end

    it 'is the zero point on an empty carrier' do
      expect(algebra.update_each([], [:image]) { |image| "registry/#{image}" }).to eq []
    end
  end

  describe '.append_each' do
    it 'appends the term to each inner array' do
      expect(algebra.append_each([[1], [2]], 9)).to eq [[1, 9], [2, 9]]
    end

    it 'is the zero point on an empty carrier' do
      expect(algebra.append_each([], 9)).to eq []
    end
  end

  describe '.index_by_name' do
    it 'finds the entry index' do
      expect(algebra.index_by_name(spec.get(:containers), 'sidecar')).to eq 1
    end

    it 'returns nil when absent' do
      expect(algebra.index_by_name(spec.get(:containers), 'ghost')).to be_nil
    end
  end

  describe '.index_by_name!' do
    it 'raises EntryNotFound when absent' do
      expect { algebra.index_by_name!(spec.get(:containers), 'ghost') }
        .to raise_error(Matsuri::Transform::EntryNotFound, /ghost/)
    end
  end

  describe '.except_entry_by_name' do
    it 'rejects the named entry' do
      remaining = algebra.except_entry_by_name(spec.get(:containers), name: 'sidecar')
      expect(remaining.map { |c| c['name'] }).to eq ['app']
    end
  end

  it 'keeps the carrier plain data through a chain of ops' do
    algebra.update_in(spec, [:containers, 0, :image]) { |image| image.sub(':1', ':2') }
    algebra.append_to(spec, [:volumes], name: 'data')
    expect(Marshal.load(Marshal.dump(spec))).to eq spec
  end
end
