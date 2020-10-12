require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to belong_to(:casa_org) }

  it { is_expected.to have_many(:case_assignments) }
  it { is_expected.to have_many(:casa_cases).through(:case_assignments) }
  it { is_expected.to have_many(:case_contacts) }

  it { is_expected.to have_many(:supervisor_volunteers) }
  it { is_expected.to have_many(:volunteers).through(:supervisor_volunteers) }

  it { is_expected.to have_one(:supervisor_volunteer) }
  it { is_expected.to have_one(:supervisor).through(:supervisor_volunteer) }

  it "requires display name" do
    user = build(:user, display_name: "")
    expect(user.valid?).to be false
  end
  it "returns all case_contacts associated with this user and the casa case id supplied" do
    volunteer = create(:volunteer, :with_casa_cases)

    case_of_interest = volunteer.casa_cases.first
    create(:case_contact, creator: volunteer, casa_case: case_of_interest)
    create(:case_contact, creator: volunteer, casa_case: volunteer.casa_cases.second)

    sample_casa_case_id = case_of_interest.id

    result = volunteer.case_contacts_for(sample_casa_case_id)

    expect(result.length).to eq(1)
  end

  it "does not return case_contacts associated with another volunteer user" do
    volunteer = create(:volunteer, :with_casa_cases)
    other_volunteer = create(:volunteer, :with_casa_cases)

    case_of_interest = volunteer.casa_cases.first
    create(:case_contact, creator: volunteer, casa_case: case_of_interest)
    create(:case_contact, creator: volunteer, casa_case: volunteer.casa_cases.second)
    create(:case_assignment, casa_case: case_of_interest, volunteer: other_volunteer)
    create(:case_contact, creator: other_volunteer, casa_case: case_of_interest)
    create(:case_contact)

    sample_casa_case_id = case_of_interest.id

    result = volunteer.case_contacts_for(sample_casa_case_id)
    expect(result.length).to eq(1)
    result = other_volunteer.case_contacts_for(sample_casa_case_id)
    expect(result.length).to eq(1)
  end

  describe "supervisors" do
    context "#volunteers_serving_transistion_aged_youth" do
      it "returns the number of transition aged youth on a supervisor" do
        assignment1 = create(:case_assignment, casa_case: create(:casa_case, transition_aged_youth: true))
        assignment2 = create(:case_assignment, casa_case: create(:casa_case, transition_aged_youth: true))
        assignment3 = create(:case_assignment, casa_case: create(:casa_case, transition_aged_youth: false))
        supervisor = create(:supervisor)
        create(:volunteer, case_assignments: [assignment1], supervisor: supervisor)
        create(:volunteer, case_assignments: [assignment2], supervisor: supervisor)
        create(:volunteer, case_assignments: [assignment3], supervisor: supervisor)
        expect(supervisor.volunteers_serving_transistion_aged_youth).to eq(2)
      end
    end

    context "#no_contact_for_two_weeks" do
      let(:supervisor) { create(:supervisor) }

      it "returns zero for a volunteer that has successfully made contact in at least one contact_case within the last 2 weeks" do
        volunteer_1 = create(:volunteer, :with_casa_cases, supervisor: supervisor)

        case_of_interest_1 = volunteer_1.casa_cases.first
        create(:case_contact, creator: volunteer_1, casa_case: case_of_interest_1, contact_made: false, occurred_at: 1.weeks.ago)
        expect(supervisor.no_contact_for_two_weeks).to eq(1)
        create(:case_contact, creator: volunteer_1, casa_case: case_of_interest_1, contact_made: true, occurred_at: 1.weeks.ago)
        expect(supervisor.no_contact_for_two_weeks).to eq(0)
      end

      it "returns one for a volunteer that has not made any contact_cases within the last 2 weeks" do
        create(:volunteer, :with_casa_cases, supervisor: supervisor)
        expect(supervisor.no_contact_for_two_weeks).to eq(1)
      end

      it "returns zero for a volunteer that is not assigned to any casa cases" do
        create(:volunteer, supervisor: supervisor)
        expect(supervisor.no_contact_for_two_weeks).to eq(0)
      end

      it "returns one for a volunteer that has successfully made contact in at least one contact_case with occurred_at after 2 weeks" do
        volunteer_1 = create(:volunteer, :with_casa_cases, supervisor: supervisor)

        case_of_interest_1 = volunteer_1.casa_cases.first

        create(:case_contact, creator: volunteer_1, casa_case: case_of_interest_1, contact_made: true, occurred_at: 3.weeks.ago)
        expect(supervisor.no_contact_for_two_weeks).to eq(1)
      end

      it "returns zero for a volunteer that has no active casa case assignments" do
        volunteer_1 = create(:volunteer, :with_casa_cases, supervisor: supervisor)

        case_of_interest_1 = volunteer_1.casa_cases.first
        case_of_interest_2 = volunteer_1.casa_cases.last
        case_assignment_1 = case_of_interest_1.case_assignments.find_by(volunteer: volunteer_1)
        case_assignment_2 = case_of_interest_2.case_assignments.find_by(volunteer: volunteer_1)
        case_assignment_1.update!(is_active: false)
        case_assignment_2.update!(is_active: false)

        expect(supervisor.no_contact_for_two_weeks).to eq(0)
      end
    end
  end

  describe "#active_for_authentication?" do
    it "is false when the user is inactive" do
      user = create(:volunteer, :inactive)
      expect(user).not_to be_active_for_authentication
      expect(user.inactive_message).to eq(:inactive)
    end

    it "is true otherwise" do
      user = create(:volunteer)
      expect(user).to be_active_for_authentication

      user = create(:supervisor)
      expect(user).to be_active_for_authentication
    end
  end

  describe "#serving_transition_aged_youth?" do
    let(:case_assignment_with_a_transition_aged_youth) do
      create(:case_assignment, casa_case: create(:casa_case, transition_aged_youth: true))
    end
    let(:case_assignment_without_transition_aged_youth) do
      create(:case_assignment, casa_case: create(:casa_case, transition_aged_youth: false))
    end

    context "when the user has a transition-aged-youth case" do
      it "is true" do
        case_assignments = [
          case_assignment_with_a_transition_aged_youth,
          case_assignment_without_transition_aged_youth
        ]
        user = create(:volunteer, case_assignments: case_assignments)

        expect(user).to be_serving_transition_aged_youth
      end
    end

    context "when the user does not have a transition-aged-youth case" do
      it "is false" do
        case_assignments = [case_assignment_without_transition_aged_youth]
        user = create(:volunteer, case_assignments: case_assignments)

        expect(user).not_to be_serving_transition_aged_youth
      end
    end
  end

  describe "#volunteers_with_no_supervisor?" do
    subject { User.volunteers_with_no_supervisor(casa_org) }
    let(:casa_org) { create(:casa_org) }
    context "no volunteers" do
      it "returns none" do
        expect(subject).to eq([])
      end
    end
    context "volunteers" do
      let!(:unassigned1) { create(:volunteer, display_name: "aaa", casa_org: casa_org) }
      let!(:unassigned2) { create(:volunteer, display_name: "bbb", casa_org: casa_org) }
      let!(:unassigned2_different_org) { create(:volunteer, display_name: "ccc") }
      let!(:assigned1) { create(:volunteer, display_name: "ddd", casa_org: casa_org) }
      let!(:assignment1) { create(:supervisor_volunteer, volunteer: assigned1) }
      let!(:assigned2_different_org) { assignment1.volunteer }
      let!(:unassigned_inactive_volunteer) { create(:volunteer, display_name: "eee", casa_org: casa_org, active: false) }
      let!(:previously_assigned) { create(:volunteer, display_name: "fff", casa_org: casa_org) }
      let!(:inactive_assignment) { create(:supervisor_volunteer, volunteer: previously_assigned, is_active: false) }

      it "returns unassigned volunteers" do
        puts 'Winz'
        expect(subject.map(&:display_name).sort).to eq(["aaa", "bbb", "fff"])
      end
    end
  end
end
