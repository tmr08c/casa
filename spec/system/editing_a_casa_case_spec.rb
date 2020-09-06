require "rails_helper"

RSpec.describe "editing a casa case", type: :system do
  context "when signed in as a volunteer" do
      it "clicks back button after editing case" do
          volunteer = create(:volunteer)
          casa_case = create(:casa_case, casa_org: volunteer.casa_org)
          case_assignment = create(:case_assignment, volunteer: volunteer, casa_case: casa_case)
          
          sign_in volunteer
          visit edit_casa_case_path(casa_case)
          check "Transition aged youth"
          click_on "Submit"
          
          has_checked_field? :transition_aged_youth

          click_on "Back"

          expect(page).to have_text("Your Case")
      end
  end

  context "when signed in as a casa admin" do
    it "clicks back button after editing case" do
      
      volunteer = create(:volunteer)
      casa_case = create(:casa_case, casa_org: volunteer.casa_org)
      case_assignment = create(:case_assignment, volunteer: volunteer, casa_case: casa_case)

      admin = create(:casa_admin, casa_org: volunteer.casa_org)
      
      sign_in admin
      
      visit edit_casa_case_path(casa_case)

      check "Transition aged youth"
      click_on "Submit"
      
      has_checked_field? :transition_aged_youth

      click_on "Back"

      expect(page).to have_text("Volunteer")
      expect(page).to have_text("Case")
      expect(page).to have_text("Supervisor")
    end
  end
  context "when signed in as a supervisor" do
    it "successfully unassigns a volunteer" do
      volunteer = create(:volunteer)
      casa_case = create(:casa_case, casa_org: volunteer.casa_org)
      case_assignment = create(:case_assignment, volunteer: volunteer, casa_case: casa_case)

      supervisor = create(:supervisor, casa_org: volunteer.casa_org)
      
      sign_in supervisor
      
      visit edit_casa_case_path(casa_case)
      # 2 case assignments, 1 w/ display name, one with name set to nil
      # in display name column for nil, should see email instead
      # xpath matcher? or page content matching, possibly css
      # jennifer, andy, adam, sean, craig(*)

    end
  end
end