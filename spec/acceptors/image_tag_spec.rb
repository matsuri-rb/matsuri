# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Matsuri::Acceptors::ImageTag do
  it 'answers the declared read' do
    expect(described_class.new(image_tag: 'v42').image_tag).to eq 'v42'
  end

  it 'defaults to latest over the empty value' do
    expect(described_class.new.image_tag).to eq 'latest'
    expect(described_class.new(image_tag: nil).image_tag).to eq 'latest'
  end

  it 'passes unconsumed vocabulary in silence, raises on undeclared reads' do
    accepted = described_class.new(image_tag: 'v42', owner: 'pipeline')

    expect(accepted.image_tag).to eq 'v42'
    expect { accepted.owner }.to raise_error(NoMethodError)
  end
end
