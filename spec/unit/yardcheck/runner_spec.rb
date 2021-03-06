# frozen_string_literal: true

RSpec.describe Yardcheck::Runner do
  subject(:runner) do
    described_class.new(observer.associate_with(docs), io)
  end

  let(:observer) { Yardcheck::SpecObserver.new(observed_events) }
  let(:docs)     { Yardcheck::Documentation.new(yardocs)        }
  let(:io)       { StringIO.new                                 }

  let(:yardocs) do
    YardcheckSpec::YARDOCS.each do |yardoc|
      allow(yardoc).to receive(:file).and_wrap_original do |method|
        File.join('./test_app', method.call).to_s
      end
    end
  end

  let(:observed_events) do
    [
      Yardcheck::MethodCall.process(
        scope:            :instance,
        selector:         :add,
        namespace:        TestApp::Namespace,
        params:           { left: 'foo', right: 3 },
        return_value:     5,
        example_location: 'test_app_spec.rb:1',
        error_raised:     false
      ),
      Yardcheck::MethodCall.process(
        scope:            :class,
        selector:         :add,
        namespace:        TestApp::Namespace.singleton_class,
        params:           { left: 2, right: 3 },
        return_value:     5,
        example_location: 'test_app_spec.rb:2',
        error_raised:     false
      )
    ]
  end

  let(:output) do
    <<~MSG
      Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum

          source: ./test_app/lib/test_app.rb:9
          tests:
            - test_app_spec.rb:2

          # Singleton method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def self.add(left, right)
            left + right
          end

      Expected TestApp::Namespace#add to receive Integer for left but observed String

          source: ./test_app/lib/test_app.rb:19
          tests:
            - test_app_spec.rb:1

          # Instance method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def add(left, right)
            left + right
          end

      Expected TestApp::Namespace#add to return String but observed Fixnum

          source: ./test_app/lib/test_app.rb:19
          tests:
            - test_app_spec.rb:1

          # Instance method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def add(left, right)
            left + right
          end

    MSG
  end

  def remove_color(string)
    string.gsub(/\e\[(?:1\;)?\d+m/, '')
  end

  shared_examples 'violation output' do
    it 'compares the spec observations against the documentation' do
      runner.check

      expect(remove_color(io.string)).to eql(output)
    end
  end

  include_examples 'violation output'

  context 'when multiple tests find the same violation' do
    let(:observed_events) do
      [
        Yardcheck::MethodCall.process(
          scope:            :instance,
          selector:         :add,
          namespace:        TestApp::Namespace,
          params:           { left: 'foo', right: 3 },
          return_value:     'valid return type',
          example_location: 'test_app_spec.rb:1',
          error_raised:     false
        ),
        Yardcheck::MethodCall.process(
          scope:            :instance,
          selector:         :add,
          namespace:        TestApp::Namespace,
          params:           { left: 'foo', right: 3 },
          return_value:     'valid return type',
          example_location: 'test_app_spec.rb:2',
          error_raised:     false
        ),
        Yardcheck::MethodCall.process(
          scope:            :instance,
          selector:         :add,
          namespace:        TestApp::Namespace,
          params:           { left: 1, right: 'now this one is wrong' },
          return_value:     'valid return type',
          example_location: 'test_app_spec.rb:3',
          error_raised:     false
        )
      ]
    end

    let(:output) do
      <<~MSG
        Expected TestApp::Namespace#add to receive Integer for left but observed String

            source: ./test_app/lib/test_app.rb:19
            tests:
              - test_app_spec.rb:1
              - test_app_spec.rb:2

            # Instance method with correct param definition and incorrect return
            #
            # @param left [Integer]
            # @param right [Integer]
            #
            # @return [String]
            def add(left, right)
              left + right
            end

        Expected TestApp::Namespace#add to receive Integer for right but observed String

            source: ./test_app/lib/test_app.rb:19
            tests:
              - test_app_spec.rb:3

            # Instance method with correct param definition and incorrect return
            #
            # @param left [Integer]
            # @param right [Integer]
            #
            # @return [String]
            def add(left, right)
              left + right
            end

      MSG
    end

    include_examples 'violation output'
  end
end
