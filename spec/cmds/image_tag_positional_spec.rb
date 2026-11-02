# frozen_string_literal: true

require 'spec_helper'

# The CLI owns the boundary mapping; the built-in ImageTag acceptor owns
# the default. One owner for 'latest', shared with the stack :image_tag
# collection — the cmd files carry no copies.
RSpec.describe 'image_tag positional' do
  let(:cmd) { Class.new { include Matsuri::Cmd }.new }

  it 'answers the acceptor default when no positional was given' do
    expect(cmd.send(:image_tag_for, nil)).to eq 'latest'
  end

  it 'passes a given positional through whole' do
    expect(cmd.send(:image_tag_for, 'v42')).to eq 'v42'
  end
end
