# frozen_string_literal: true

Matsuri.define :pod, 'report' do
  let(:image_tag) { options[:image_tag] || 'latest' }

  let(:spec) do
    { containers: [{ name: 'report', image: "report:#{image_tag}" }] }
  end
end
