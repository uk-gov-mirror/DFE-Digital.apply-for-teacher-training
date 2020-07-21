require 'rails_helper'

RSpec.describe SetRejectByDefault do
  describe '#call' do
    it 'does not update dates when nothing changes', with_audited: true do
      application_choice = create(:application_choice, sent_to_provider_at: Time.zone.now)

      expect { call_service(application_choice) }.to change { Audited::Audit.count }.by(1)
      expect { call_service(application_choice) }.to change { Audited::Audit.count }.by(0)
    end
  end

  describe 'RBD calculation' do
    submitted_vs_rbd_dates = [
      ['2 Sept 2019 9:00:00 AM BST', '29 Oct 2019 0:00:00 AM GMT', 'near the BST/GMT boundary'],
      ['1 Jul 2019 9:00:00 AM BST',  '28 Aug 2019 0:00:00 AM BST', 'safely within BST'],
      ['4 Jan 2019 11:00:00 PM GMT', '2 Mar 2019 0:00:00 AM GMT',  'safely within GMT'],
      ['1 Jul 2020 11:00:00 PM BST', '30 Jul 2020 0:00:00 AM BST', 'during the 20-day summer period'],
    ].freeze

    submitted_vs_rbd_dates.each do |submitted, correct_rbd, test_case|
      it "is correct when the application is delivered #{test_case}" do
        choice = create(:application_choice, sent_to_provider_at: submitted)

        call_service(choice)

        expect(choice.reload.reject_by_default_at).to be_within(1.second).of(Time.zone.parse(correct_rbd))
      end
    end
  end

  def call_service(application_choice)
    SetRejectByDefault.new(application_choice).call
  end
end
