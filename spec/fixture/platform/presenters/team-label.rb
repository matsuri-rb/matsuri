# frozen_string_literal: true

# Stamps the owning team onto the manifest's labels.
Matsuri.define :presenter, 'team-label' do
  def transform(manifest)
    set_label(manifest.get(:metadata), :team, 'platform')
    manifest
  end
end
