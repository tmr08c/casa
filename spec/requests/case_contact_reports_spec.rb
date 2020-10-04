require "rails_helper"

RSpec.describe "/case_contact_reports", type: :request do
  describe "GET /case_contact_reports with start_date and end_date" do
    it "renders a csv file to download" do
      sign_in create(:volunteer)
      create(:case_contact)

      get case_contact_reports_url(format: :csv), params: case_contact_report_params

      expect(response).to be_successful
      expect(
        response.headers["Content-Disposition"]
      ).to include 'attachment; filename="case-contacts-report-'
    end
  end

  describe "GET /case_contact_reports without start_date and end_date" do
    it "renders a csv file to download" do
      sign_in create(:volunteer)
      create(:case_contact)

      get case_contact_reports_url(format: :csv)

      expect(response).to be_successful
      expect(
        response.headers["Content-Disposition"]
      ).to include 'attachment; filename="case-contacts-report-'
    end
  end

  context 'as a volunteer' do
    before do
      sign_in create(:volunteer)
    end

    it "renders csv ignoring unallowed filters" do
      volunteer = create(:volunteer)
      contact = create(:case_contact, {occurred_at: 20.days.ago, creator_id: volunteer.id})
      create(:case_contact, {occurred_at: 20.days.ago})

      #get case_contact_reports_url(format: :csv), params: { creator_ids: [volunteer.id] }
      get "/case_contact_reports.csv?start_date=2020-09-04&end_date=2020-10-04&creator_ids%5B%5D=&commit=Download+Report"
      expect(response).to be_successful
      expect(
        response.headers["Content-Disposition"]
      ).to include 'attachment; filename="case-contacts-report-'
      expect(response.body).to match(/^#{contact.id},/)
      expect(response.body.lines.length).to eq(3)
    end

  end

  context 'as an admin' do
    before do
      sign_in create(:casa_admin)
    end

    describe "GET /case_contact_reports with supervisor_ids filter" do
      it "renders csv with only the volunteer" do
        volunteer = create(:volunteer)
        contact = create(:case_contact, {occurred_at: 20.days.ago, creator_id: volunteer.id})
        create(:case_contact, {occurred_at: 100.days.ago})

        get case_contact_reports_url(format: :csv), params: { creator_ids: [volunteer.id] }

        expect(response).to be_successful
        expect(
          response.headers["Content-Disposition"]
        ).to include 'attachment; filename="case-contacts-report-'
        expect(response.body).to match(/^#{contact.id},/)
        expect(response.body.lines.length).to eq(2)
      end
    end
  end

  def case_contact_report_params
    {
      start_date: 1.month.ago,
      end_date: Date.today
    }
  end
end
