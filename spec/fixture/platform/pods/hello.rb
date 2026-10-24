Matsuri.define :pod, 'hello' do
  let(:spec) do
    { containers: [{ name: 'hello', image: 'nginx:1.25' }] }
  end
end
