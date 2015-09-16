require 'rlet'
require 'rlet/lazy_options'

module Matsuri
  module Task
    extend Concern

    included do
      include Let
      include RLet::LazyOptions
      include Matsuri::ShellOut

      let(:verbose) { options[:verbose] || config.verbose }
      let(:debug)   { options[:debug]   || config.debug }
      let(:config)  { Matsuri::Config }
    end
  end
end
