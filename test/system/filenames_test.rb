require "application_system_test_case"

class FilenamesTest < ApplicationSystemTestCase
  setup do
    @filename = filenames(:one)
  end

  test "visiting the index" do
    visit filenames_url
    assert_selector "h1", text: "Filenames"
  end

  test "creating a Filename" do
    visit filenames_url
    click_on "New Filename"

    fill_in "Name", with: @filename.name
    click_on "Create Filename"

    assert_text "Filename was successfully created"
    click_on "Back"
  end

  test "updating a Filename" do
    visit filenames_url
    click_on "Edit", match: :first

    fill_in "Name", with: @filename.name
    click_on "Update Filename"

    assert_text "Filename was successfully updated"
    click_on "Back"
  end

  test "destroying a Filename" do
    visit filenames_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Filename was successfully destroyed"
  end
end
