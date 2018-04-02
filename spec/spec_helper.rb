# frozen_string_literal: true

require 'cocoapods'

module Pod
  # Disable the wrapping so the output is deterministic in the tests.
  #
  UI.disable_wrap = true

  # Redirects the messages to an internal store.
  #
  module UI
    class << self
      attr_accessor :output
      attr_accessor :warnings
      attr_accessor :next_input

      def puts(message = '')
        @output << "#{message}\n"
      end

      def warn(message = '', _actions = [])
        @warnings << "#{message}\n"
      end

      def print(message)
        @output << message
      end

      alias gets next_input

      def print_warnings; end
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do
    Pod::UI.output = ''.dup
    Pod::UI.warnings = ''.dup
    Pod::UI.next_input = ''.dup
    Pod::Config.instance = nil
  end
end
