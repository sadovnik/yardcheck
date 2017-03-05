# frozen_string_literal: true

module Yardcheck
  class Typedef
    include Concord.new(:types)

    def self.parse(types)
      if types.include?(:undefined)
        fail 'Cannot combined [undefined] with other types' unless types.one?
        Undefined.new
      else
        new(types)
      end
    end

    def match?(other)
      types.any? do |type|
        type.match?(other)
      end
    end

    def signature
      types.to_a.map { |type| type.signature }.join(' | ')
    end

    def +(other)
      self.class.new((types + other.types).uniq)
    end

    class Literal < self
      include Concord.new(:type_class)

      def match?(other)
        begin
          type_class == other || other < type_class
        rescue
          require 'pry'; require 'pry-byebug'; binding.pry
        end
      end

      def signature
        type_class.inspect
      end
    end

    class Collection < self
      include Concord.new(:collection_class, :member_typedefs)

      def match?(other)
        other == collection_class
      end

      def signature
        "#{collection_class}<#{member_typedefs.map(&:signature)}>"
      end
    end

    class Undefined < self
      include Concord.new

      def match?(_)
        true
      end

      def signature
        'Undefined'
      end
    end # Undefined
  end # Typedef
end # Yardcheck
