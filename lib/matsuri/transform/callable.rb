# frozen_string_literal: true

module Matsuri
  module Transform
    # The free monoid over manifest transforms. A Callable holds an ordered
    # member list and #call reduces the manifest through it. new = identity,
    # new(label:) { ... } = leaf, new([a, b]) = composite. + concatenates the
    # operands' member lists into a new instance, so identity and
    # associativity hold on the nose. Members are never flattened: a
    # composite passed as a member stays one member, and label rides along
    # as trace metadata.
    #
    # Coercion happens at construction and fails fast: anything #call-able is
    # taken as-is; a Symbol or String names a registered presenter.
    class Callable
      attr_reader :members, :label

      def initialize(members = nil, label: nil, &blk)
        raise ArgumentError, 'pass members or a block, not both' if blk && members

        @label = label
        @members =
          if blk
            [blk]
          elsif members.nil?
            []
          else
            Array(members).map { |m| coerce(m) }
          end
      end

      def +(other)
        other_members = other.is_a?(Callable) ? other.members : [coerce(other)]
        self.class.new(members + other_members)
      end

      def call(manifest)
        members.reduce(manifest) { |m, member| member.call(m) }
      end

      private

      def coerce(member)
        case member
        when Symbol, String then Matsuri::Registry.presenter(member)
        else
          return member if member.respond_to?(:call)

          raise ArgumentError, "cannot compose #{member.inspect}: not #call-able or a presenter name"
        end
      end
    end
  end
end
