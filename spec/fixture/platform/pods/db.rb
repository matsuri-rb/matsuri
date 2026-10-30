# frozen_string_literal: true

Matsuri.define :pod, 'db' do
  let(:image_tag) { options[:image_tag] || 'latest' }

  let(:spec) do
    { containers: [{ name: 'db', image: "postgres:#{image_tag}" }] }
  end
end
