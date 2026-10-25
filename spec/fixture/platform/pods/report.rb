# frozen_string_literal: true

Matsuri.define :pod, 'report' do
  let(:spec) do
    { containers: [{ name: 'report', image: "report:#{image_tag}" }] }
  end
end
