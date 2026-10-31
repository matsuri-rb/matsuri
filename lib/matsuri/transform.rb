# frozen_string_literal: true

module Matsuri
  # Pure manifest transformation strata. Nothing under this namespace shells
  # out or touches a cluster; everything operates on plain data (Map / Hash /
  # Array) and composes as values.
  module Transform
    autoload :Algebra,     'matsuri/transform/algebra'
    autoload :Callable,    'matsuri/transform/callable'
    autoload :Env,         'matsuri/transform/env'
    autoload :Kubernetes,  'matsuri/transform/kubernetes'
    autoload :Combinators, 'matsuri/transform/combinators'

    # Raised by strict by-name lookups when no entry matches.
    class EntryNotFound < StandardError; end

    # Raised by path-addressed ops when nothing exists at the path.
    class PathNotFound < StandardError; end
  end
end
