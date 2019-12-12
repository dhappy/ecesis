require "application_system_test_case"

class BooksCategoriesTest < ApplicationSystemTestCase
  setup do
    @books_category = books_categories(:one)
  end

  test "visiting the index" do
    visit books_categories_url
    assert_selector "h1", text: "Books Categories"
  end

  test "creating a Books category" do
    visit books_categories_url
    click_on "New Books Category"

    fill_in "Book", with: @books_category.book_id
    fill_in "Category", with: @books_category.category_id
    click_on "Create Books category"

    assert_text "Books category was successfully created"
    click_on "Back"
  end

  test "updating a Books category" do
    visit books_categories_url
    click_on "Edit", match: :first

    fill_in "Book", with: @books_category.book_id
    fill_in "Category", with: @books_category.category_id
    click_on "Update Books category"

    assert_text "Books category was successfully updated"
    click_on "Back"
  end

  test "destroying a Books category" do
    visit books_categories_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Books category was successfully destroyed"
  end
end
