require "test_helper"

class AppBuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AppBuilder::VERSION
  end
end
