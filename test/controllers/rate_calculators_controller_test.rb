require 'test_helper'

class RateCalculatorsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get rate_calculators_new_url
    assert_response :success
  end

  test "should get index" do
    get rate_calculators_index_url
    assert_response :success
  end

end
