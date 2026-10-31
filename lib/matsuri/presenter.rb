# frozen_string_literal: true

require 'rlet'

module Matsuri
  # A presenter is one manifest-shaped step in a delivery pipeline:
  # Manifest -> Manifest, zero-config and context-free. Construction takes
  # nothing; parameterization happens before #call ever runs — definition
  # lets filling a concern's declared holes, or declaration-time values
  # closed over in a leaf Callable.
  #
  # #call is framework-owned: it makes the one boundary copy and delegates
  # to #transform, which authors implement against a carrier that is already
  # theirs to mutate. The base #transform is the identity, so the bare
  # Presenter is the identity element. A fresh instance serves each call, so
  # let memoization scopes to a single manifest pass. The Kubernetes dialect
  # (Transform::Kubernetes, carrying Algebra + Env) is bare vocabulary
  # inside #transform.
  class Presenter
    include Let
    include Matsuri::Transform::Kubernetes

    class << self
      def call(manifest)
        new.call(manifest)
      end

      def load_path
        Matsuri::Config.presenters_path
      end

      def definition_module_name
        'Presenters'
      end
    end

    # Marshal is the copy because the carrier is data — Map.new alone shares
    # nested structure with the input.
    def call(manifest)
      transform(Map.new(Marshal.load(Marshal.dump(manifest))))
    end

    def transform(manifest)
      manifest
    end
  end
end
