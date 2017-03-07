module Yardcheck
  class TestValue
    include Concord.new(:value)

    def self.process(value)
      case value
      when RSpec::Mocks::InstanceVerifyingDouble
        InstanceDouble.process(value)
      when RSpec::Mocks::Double
        Double.process(value)
      else
        new(value)
      end
    end

    def is?(annotated_value)
      if annotated_value.is_a?(Module)
        value.is_a?(annotated_value)
      else
        value == annotated_value
      end
    end

    def type
      value.class
    end

    def inspect
      "#{self.class}.new(#{value.inspect})"
    end

    class InstanceDouble < self
      include Concord.new(:doubled_module)

      def self.process(value)
        new(value.instance_variable_get(:@doubled_module).target)
      end

      def is?(klass)
        doubled_module == klass || doubled_module < klass
      end

      def type
        doubled_module
      end

      def inspect
        "#{self.class}.new(#{doubled_module.inspect})"
      end
    end

    class Double < self
      include Concord.new(:name)

      def self.process(value)
        new(value.instance_variable_get(:@name) || '(anonymous)')
      end

      def is?(_)
        true
      end

      def type
        '(double)'
      end

      def inspect
        "#{self.class}.new(#{name.inspect})"
      end
    end
  end
end
