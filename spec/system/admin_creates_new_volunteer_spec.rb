require "rails_helper"

RSpec.describe "Admin: New volunteer", type: :system do
  let(:admin) { create(:volunteer) }

  it "allows admin to create a new supervisors" do
    sign_in admin
    visit new_volunteer_path

    fill_in "Email", with: "new_volunteer@example.com"
    # fill_in "Display Name", with: "New Volunteer Display Name"

    expect {
      click_on "Create Volunteer"
    }.to change(User, :count).by(1)
  end
end