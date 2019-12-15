require 'test_helper'

class FilenamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @filename = filenames(:one)
  end

  test "should get index" do
    get filenames_url
    assert_response :success
  end

  test "should get new" do
    get new_filename_url
    assert_response :success
  end

  test "should create filename" do
    assert_difference('Filename.count') do
      post filenames_url, params: { filename: { name: @filename.name } }
    end

    assert_redirected_to filename_url(Filename.last)
  end

  test "should show filename" do
    get filename_url(@filename)
    assert_response :success
  end

  test "should get edit" do
    get edit_filename_url(@filename)
    assert_response :success
  end

  test "should update filename" do
    patch filename_url(@filename), params: { filename: { name: @filename.name } }
    assert_redirected_to filename_url(@filename)
  end

  test "should destroy filename" do
    assert_difference('Filename.count', -1) do
      delete filename_url(@filename)
    end

    assert_redirected_to filenames_url
  end
end
