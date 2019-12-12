require 'test_helper'

class BooksCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @books_category = books_categories(:one)
  end

  test "should get index" do
    get books_categories_url
    assert_response :success
  end

  test "should get new" do
    get new_books_category_url
    assert_response :success
  end

  test "should create books_category" do
    assert_difference('BooksCategory.count') do
      post books_categories_url, params: { books_category: { book_id: @books_category.book_id, category_id: @books_category.category_id } }
    end

    assert_redirected_to books_category_url(BooksCategory.last)
  end

  test "should show books_category" do
    get books_category_url(@books_category)
    assert_response :success
  end

  test "should get edit" do
    get edit_books_category_url(@books_category)
    assert_response :success
  end

  test "should update books_category" do
    patch books_category_url(@books_category), params: { books_category: { book_id: @books_category.book_id, category_id: @books_category.category_id } }
    assert_redirected_to books_category_url(@books_category)
  end

  test "should destroy books_category" do
    assert_difference('BooksCategory.count', -1) do
      delete books_category_url(@books_category)
    end

    assert_redirected_to books_categories_url
  end
end
