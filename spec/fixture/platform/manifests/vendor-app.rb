# frozen_string_literal: true

# A vendor bundle customized locally: the deployment's pod spec gains an
# env entry through the transform dialect; the service passes through.
Matsuri.define :imported_manifest, 'vendor-app' do
  let(:namespace)   { 'specs' }
  let(:import_path) { 'vendor-app.yaml' }

  let(:extracted_manifests) do
    imported_manifests.map { |doc| Map.new(doc) }.map do |doc|
      next doc unless doc.get(:kind) == 'Deployment'

      update_in(doc, [:spec, :template, :spec]) do |pod_spec|
        set_env(pod_spec, 'IMPORTED', 'true')
      end
    end
  end
end
