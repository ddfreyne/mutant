# frozen_string_literal: true

module Mutant
  # Abstract base class for mutant environments
  class Env
    include Adamantium::Flat, Anima.new(
      :config,
      :integration,
      :matchable_scopes,
      :mutations,
      :parser,
      :selector,
      :subjects,
      :world
    )

    class Selection
      include Concord::Public.new(:mutation, :tests)
    end

    private_constant(*constants(false))

    SEMANTICS_MESSAGE =
      "Fix your lib to follow normal ruby semantics!\n" \
      '{Module,Class}#name should return resolvable constant name as String or nil'

    # Construct minimal empty env
    #
    # @param [World] world
    # @param [Config] config
    #
    # @return [Env]
    def self.empty(world, config)
      new(
        config:           config,
        integration:      Integration::Null.new(config),
        matchable_scopes: EMPTY_ARRAY,
        mutations:        EMPTY_ARRAY,
        parser:           Parser.new,
        selector:         Selector::Null.new,
        subjects:         EMPTY_ARRAY,
        world:            world
      )
    end

    # Kill mutation
    #
    # @param [Mutation] mutation
    #
    # @return [Result::Mutation]
    def kill(mutation)
      start = Timer.now

      tests = selections.fetch(mutation.subject)

      Result::Mutation.new(
        isolation_result: run_selection_isolation(Selection.new(mutation, tests)),
        mutation:         mutation,
        runtime:          Timer.now - start
      )
    end

    # The test selections
    #
    # @return Hash{Mutation => Enumerable<Test>}
    def selections
      subjects.map do |subject|
        [subject, selector.call(subject)]
      end.to_h
    end
    memoize :selections

    # Emit warning
    #
    # @param [String] warning
    #
    # @return [self]
    def warn(message)
      config.reporter.warn(message)
      self
    end

    # Selected tests
    #
    # @return [Set<Test>]
    def selected_tests
      selections.values.flatten.to_set
    end
    memoize :selected_tests

    # Amount of mutations
    #
    # @return [Integer]
    def amount_mutations
      mutations.length
    end
    memoize :amount_mutations

    # Amount of tests reachable by integration
    #
    # @return [Integer]
    def amount_total_tests
      integration.all_tests.length
    end
    memoize :amount_total_tests

    # Amount of selected subjects
    #
    # @return [Integer]
    def amount_subjects
      subjects.length
    end
    memoize :amount_subjects

    # Amount of selected tests
    #
    # @return [Integer]
    def amount_selected_tests
      selected_tests.length
    end
    memoize :amount_selected_tests

    # Ratio between selected tests and subjects
    #
    # @return [Rational]
    def test_subject_ratio
      return Rational(0) if amount_subjects.zero?

      Rational(amount_selected_tests, amount_subjects)
    end
    memoize :test_subject_ratio

  private

    # Kill mutation under isolation with integration
    #
    # @param [Selection] selection
    #
    # @return [Result::Isolation]
    def run_selection_isolation(selection)
      config.isolation.call do
        run_selection_integration(selection)
      end
    end

    # Kill mutation with integration
    #
    # @param [Selection] selection
    #
    # @return [Result::Test]
    def run_selection_integration(selection)
      result = selection.mutation.insert(world.kernel)

      if result.equal?(Loader::Result::VoidValue.instance)
        Result::Test::VoidValue.instance
      else
        integration.call(selection.tests)
      end
    end
  end # Env
end # Mutant
