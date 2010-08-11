require 'rubygems'
require 'test/unit'
require 'mocha'


$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'active_merchant_tranzila'

ActiveMerchant::Billing::Base.mode = :test

module ActiveMerchant
  module Assertions
    AssertionClass = RUBY_VERSION > '1.9' ? MiniTest::Assertion : Test::Unit::AssertionFailedError

    def assert_field(field, value)
      clean_backtrace do
        assert_equal value, @helper.fields[field]
      end
    end

    # Allows the testing of you to check for negative assertions:
    #
    #   # Instead of
    #   assert !something_that_is_false
    #
    #   # Do this
    #   assert_false something_that_should_be_false
    #
    # An optional +msg+ parameter is available to help you debug.
    def assert_false(boolean, message = nil)
      message = build_message message, '<?> is not false or nil.', boolean

      clean_backtrace do
        assert_block message do
          not boolean
        end
      end
    end

    # A handy little assertion to check for a successful response:
    #
    #   # Instead of
    #   assert_success response
    #
    #   # DRY that up with
    #   assert_success response
    #
    # A message will automatically show the inspection of the response
    # object if things go afoul.
    def assert_success(response)
      clean_backtrace do
        assert response.success?, "Response failed: #{response.inspect}"
      end
    end

    # The negative of +assert_success+
    def assert_failure(response)
      clean_backtrace do
        assert_false response.success?, "Response expected to fail: #{response.inspect}"
      end
    end

    def assert_valid(validateable)
      clean_backtrace do
        assert validateable.valid?, "Expected to be valid"
      end
    end

    def assert_not_valid(validateable)
      clean_backtrace do
        assert_false validateable.valid?, "Expected to not be valid"
      end
    end

    private
    def clean_backtrace(&block)
      yield
    rescue AssertionClass => e
      path = File.expand_path(__FILE__)
      raise AssertionClass, e.message, e.backtrace.reject { |line| File.expand_path(line) =~ /#{path}/ }
    end
  end

  module Fixtures
    private
    def credit_card(number = '4242424242424242', options = {})
      defaults = {
        :number => number,
        :month => 9,
        :year => Time.now.year + 1,
        :first_name => 'Longbob',
        :last_name => 'Longsen',
        :verification_value => '123',
        :type => 'visa'
      }.update(options)

      Billing::CreditCard.new(defaults)
    end
  end
end

class Test::Unit::TestCase
  include ActiveMerchant::Billing
  include ActiveMerchant::Fixtures
  include ActiveMerchant::Assertions
end
