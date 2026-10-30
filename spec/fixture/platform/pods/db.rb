# frozen_string_literal: true

# The image is pinned: a database does not track the app's version. The
# converge positional passes this pod in silence — it never declared the
# read.
Matsuri.define :pod, 'db' do
  let(:container) { { name: 'db', image: 'postgres:latest' } }
  let(:volumes)   { [] }
end
