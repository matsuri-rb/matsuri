# frozen_string_literal: true

# The one member that listens: image_tag is a declared read, interpolated
# into the image with no default of its own — the stack's acceptor owns
# the default.
Matsuri.define :pod, 'web' do
  let(:container) { { name: 'web', image: "app:#{image_tag}" } }
  let(:volumes)   { [] }
end
