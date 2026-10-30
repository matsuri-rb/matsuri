# frozen_string_literal: true

Matsuri.define :pod, 'web' do
  let(:image_tag) { options[:image_tag] || 'latest' }

  let(:spec) do
    { containers: [{ name: 'web', image: "app:#{image_tag}" }] }
  end
end
