# frozen_string_literal: true

require 'rlet'
require 'rlet/lazy_options'

module Matsuri
  # An acceptor admits a value whose vocabulary matsuri does not own, such as
  # a stack-config artifact. The raw value arrives whole as options; the lets
  # declared here are the accepted surface, and members read the acceptor
  # instead of the raw value. Fields the acceptor does not declare are
  # ignored. Reads the acceptor does not declare raise NoMethodError. There
  # is no fallback to the underlying value.
  class Acceptor
    include Let
    include RLet::LazyOptions

    class << self
      def load_path
        Matsuri::Config.acceptors_path
      end

      def definition_module_name
        'Acceptors'
      end
    end
  end
end
