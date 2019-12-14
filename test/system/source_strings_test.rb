require "application_system_test_case"

class SourceStringsTest < ApplicationSystemTestCase
  setup do
    @source_string = source_strings(:one)
  end

  test "visiting the index" do
    visit source_strings_url
    assert_selector "h1", text: "Source Strings"
  end

  test "creating a Source string" do
    visit source_strings_url
    click_on "New Source String"

    fill_in "Text", with: @source_string.text
    click_on "Create Source string"

    assert_text "Source string was successfully created"
    click_on "Back"
  end

  test "updating a Source string" do
    visit source_strings_url
    click_on "Edit", match: :first

    fill_in "Text", with: @source_string.text
    click_on "Update Source string"

    assert_text "Source string was successfully updated"
    click_on "Back"
  end

  test "destroying a Source string" do
    visit source_strings_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Source string was successfully destroyed"
  end
end
