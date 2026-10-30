# frozen_string_literal: true

require 'matsuri/acceptor'

module Matsuri
  module Acceptors
    # Built-in acceptor for the :image_tag collection on stacks. Maps the
    # converge positional — a scalar, admitted whole — onto the declared
    # surface. The 'latest' default lives here and nowhere else; a platform
    # overrides it by re-declaring the collection with its own acceptor.
    class ImageTag < Matsuri::Acceptor
      let(:image_tag) { options || 'latest' }
    end
  end
end
