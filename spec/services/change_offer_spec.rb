require 'rails_helper'

RSpec.describe ChangeOffer do
  include CourseOptionHelpers
  let(:provider_user) { create(:provider_user, :with_provider, :with_make_decisions) }
  let(:provider) { provider_user.providers.first }
  let(:original_course_option) { course_option_for_provider(provider: provider) }
  let(:new_course_option) { course_option_for_provider(provider: provider) }
  let(:application_choice) do
    choice = create(:application_choice, :with_modified_offer, course_option: original_course_option)
    SetDeclineByDefault.new(application_form: choice.application_form).call # fix DBD
    choice.reload
  end

  let(:conditions) { [] }
  let(:offer) { Offer.new(application_choice: application_choice, course_option: new_course_option, conditions: conditions) }

  def service
    ChangeOffer.new(actor: provider_user, offer: offer)
  end

  it 'changes offered_course_option_id for the application choice' do
    expect { service.save }.to change(application_choice, :offered_course_option_id)
  end

  it 'does not change offered_at' do
    expect { service.save }.not_to change(application_choice, :offered_at)
  end

  it 'populates offer_changed_at for the application choice' do
    Timecop.freeze do
      expect { service.save }.to change(application_choice, :offer_changed_at).to(Time.zone.now)
    end
  end

  it 'groups offer(ed) changes in a single audit', with_audited: true do
    service.save

    audit_with_option_id =
      application_choice.audits
      .where('jsonb_exists(audited_changes, :key)', key: 'offered_course_option_id')
      .last

    expect(audit_with_option_id.audited_changes).to have_key('offer_changed_at')
  end

  context 'when conditions are supplied' do
    let(:conditions) { ['First condition', 'Second condition'] }

    it 'replaces conditions if offer_conditions is supplied' do
      application_choice.update(offer: { 'conditions' => ['DBS check'] })

      expect { service.save }.to change(application_choice, :offer)
      expect(application_choice.offer['conditions']).to eq(['First condition', 'Second condition'])
    end
  end

  it 'resets declined_by_default_at for the application choice' do
    expect { service.save && application_choice.reload }.to change(application_choice, :decline_by_default_at)
  end

  it 'sends an email to the candidate to notify them about the change' do
    mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(CandidateMailer).to receive(:changed_offer).and_return(mail)

    service.save

    expect(CandidateMailer).to have_received(:changed_offer).with(application_choice)
    expect(mail).to have_received(:deliver_later)
  end

  it 'calls `StateChangeNotifier` to send a Slack notification' do
    allow(StateChangeNotifier).to receive(:call).and_return(nil)
    service.save
    expect(StateChangeNotifier).to have_received(:call).with(:change_an_offer, application_choice: application_choice)
  end
end
