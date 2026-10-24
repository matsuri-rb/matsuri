Matsuri.define :pod, 'db' do
  let(:spec) do
    { containers: [{ name: 'db', image: "postgres:#{image_tag}" }] }
  end
end
