# frozen_string_literal: true

require 'spec_helper'

# The :image_tag collection carries a scalar: the acceptor admits the
# converge positional whole. The empty value is nil, which is what the
# collection projects when no positional was given.
RSpec.describe Matsuri::Acceptors::ImageTag do
  it 'admits the scalar whole' do
    expect(described_class.new('v42').image_tag).to eq 'v42'
  end

  it 'defaults to latest over the empty value' do
    expect(described_class.new(nil).image_tag).to eq 'latest'
  end

  it 'raises on undeclared reads' do
    expect { described_class.new('v42').owner }.to raise_error(NoMethodError)
  end
end
