require 'spec_helper'
require 'matsuri/version'

RSpec.describe Matsuri do
  it 'has a version number' do
    expect(Matsuri::VERSION).not_to be nil
  end

  describe '.define' do
    it 'defines and registers a resource class' do
      klass = Matsuri.define(:pod, 'define-test') do
        let(:spec) { { containers: [{ name: 'c', image: 'i' }] } }
      end

      expect(Matsuri::Registry.pod('define-test')).to eq klass
    end

    it 'builds the subclass chain through inherits:' do
      parent = Matsuri.define(:pod, 'define-parent') do
        let(:spec) { { containers: [{ name: 'c', image: 'i' }] } }
      end
      child = Matsuri.define(:pod, 'define-child', inherits: 'define-parent')

      expect(child).to be < parent
    end
  end
end
