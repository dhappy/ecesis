require 'test_helper'

class SourceStringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source_string = source_strings(:one)
  end

  test "should get index" do
    get source_strings_url
    assert_response :success
  end

  test "should get new" do
    get new_source_string_url
    assert_response :success
  end

  test "should create source_string" do
    assert_difference('SourceString.count') do
      post source_strings_url, params: { source_string: { text: @source_string.text } }
    end

    assert_redirected_to source_string_url(SourceString.last)
  end

  test "should show source_string" do
    get source_string_url(@source_string)
    assert_response :success
  end

  test "should get edit" do
    get edit_source_string_url(@source_string)
    assert_response :success
  end

  test "should update source_string" do
    patch source_string_url(@source_string), params: { source_string: { text: @source_string.text } }
    assert_redirected_to source_string_url(@source_string)
  end

  test "should destroy source_string" do
    assert_difference('SourceString.count', -1) do
      delete source_string_url(@source_string)
    end

    assert_redirected_to source_strings_url
  end
end
