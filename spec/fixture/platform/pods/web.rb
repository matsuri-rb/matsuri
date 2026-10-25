# frozen_string_literal: true

Matsuri.define :pod, 'web' do
  let(:spec) do
    { containers: [{ name: 'web', image: "app:#{image_tag}" }] }
  end
end
