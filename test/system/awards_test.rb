require "application_system_test_case"

class AwardsTest < ApplicationSystemTestCase
  setup do
    @award = awards(:one)
  end

  test "visiting the index" do
    visit awards_url
    assert_selector "h1", text: "Awards"
  end

  test "creating a Award" do
    visit awards_url
    click_on "New Award"

    fill_in "Description", with: @award.description
    fill_in "Name", with: @award.name
    click_on "Create Award"

    assert_text "Award was successfully created"
    click_on "Back"
  end

  test "updating a Award" do
    visit awards_url
    click_on "Edit", match: :first

    fill_in "Description", with: @award.description
    fill_in "Name", with: @award.name
    click_on "Update Award"

    assert_text "Award was successfully updated"
    click_on "Back"
  end

  test "destroying a Award" do
    visit awards_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Award was successfully destroyed"
  end
end
