module Mutant
  class Killer
    # Runner for rspec tests
    class Rspec < self
      TYPE = 'rspec'.freeze

      # Run block in clean rspec environment
      #
      # @return [Object]
      #   returns the value of block
      #
      # @api private
      #
      def self.nest
        original_world, original_configuration = 
          ::RSpec.instance_variable_get(:@world),
          ::RSpec.instance_variable_get(:@configuration)

        ::RSpec.reset

        yield
      ensure
        ::RSpec.instance_variable_set(:@world, original_world)
        ::RSpec.instance_variable_set(:@configuration, original_configuration)
      end

    private

      # Initialize rspec runner
      #
      # @return [undefined]
      #
      # @api private
      #
      def initialize(*)
        @error_stream, @output_stream = StringIO.new, StringIO.new
        super
      end

      # Run rspec test
      #
      # @return [true]
      #   returns true when test is NOT successful and the mutant was killed
      #
      # @return [false]
      #   returns false otherwise
      #
      # @api private
      #
      def run
        !run_rspec.zero?
      end
      memoize :run

      # Run rspec with some wired compat stuff
      #
      # FIXME: This extra stuff needs to be configurable per project
      #
      # @return [Fixnum]
      #   returns the exit status from rspec runner
      #
      # @api private
      #
      def run_rspec
        self.class.nest do 
          ::RSpec::Core::Runner.run(command_line_arguments, @error_stream, @output_stream)
        end
      end

      # Return command line arguments
      #
      # @return [Array]
      #
      # @api private
      #
      def command_line_arguments
        %W(
          --fail-fast
        ) + Dir[filename_pattern]
      end

      # Return filename pattern
      #
      # @return [String]
      #
      # @api private
      #
      def filename_pattern
        strategy.filename_pattern(mutation)
      end
    end
  end
end
