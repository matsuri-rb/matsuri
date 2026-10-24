require 'spec_helper'

RSpec.describe 'matsuri/core_ext' do
  describe 'Hash key transforms' do
    it 'deep symbolizes keys through nested hashes and arrays' do
      expect({ 'a' => [{ 'b' => 1 }], 'c' => { 'd' => 2 } }.deep_symbolize_keys)
        .to eq(a: [{ b: 1 }], c: { d: 2 })
    end

    it 'deep stringifies keys through nested hashes and arrays' do
      expect({ a: [{ b: 1 }], c: { d: 2 } }.deep_stringify_keys)
        .to eq('a' => [{ 'b' => 1 }], 'c' => { 'd' => 2 })
    end

    it 'leaves unsymbolizable keys alone' do
      expect({ 1 => 'x' }.deep_symbolize_keys).to eq(1 => 'x')
    end
  end

  describe 'Object#try' do
    it 'returns nil on nil receiver' do
      expect(nil.try(:to_s)).to be_nil
    end

    it 'returns nil when the receiver does not respond' do
      expect(Object.new.try(:no_such_method)).to be_nil
    end

    it 'calls through when the receiver responds' do
      expect('x'.try(:upcase)).to eq 'X'
    end
  end

  describe 'blank? / present? / presence' do
    it 'treats nil, false, empty and whitespace strings, and empty collections as blank' do
      expect([nil, false, '', '  ', [], {}].all?(&:blank?)).to be true
    end

    it 'treats values and non-empty collections as present' do
      expect(['x', 0, [1], { a: 1 }].all?(&:present?)).to be true
    end

    it 'returns self or nil from presence' do
      expect('x'.presence).to eq 'x'
      expect(''.presence).to be_nil
    end
  end

  describe 'String#camelize' do
    it 'camelizes underscored names' do
      expect('load_balancer'.camelize).to eq 'LoadBalancer'
    end

    it 'camelizes dasherized names after underscore normalization' do
      expect('my-pod-2'.gsub(/-/, '_').camelize).to eq 'MyPod2'
    end
  end

  describe 'Class#class_attribute' do
    let(:parent) { Class.new.tap { |k| k.class_attribute :build_order } }

    it 'isolates subclass writes from the parent' do
      child = Class.new(parent)
      child.build_order = [1]

      expect(parent.build_order).to be_nil
      expect(child.build_order).to eq [1]
    end

    it 'inherits the parent value until overridden' do
      parent.build_order = [:a]

      expect(Class.new(parent).build_order).to eq [:a]
    end

    it 'exposes an instance reader' do
      parent.build_order = [:a]

      expect(parent.new.build_order).to eq [:a]
    end
  end
end
