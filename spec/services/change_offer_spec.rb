require 'rails_helper'

RSpec.describe ChangeOffer do
  include CourseOptionHelpers

  let(:change_offer) do
    ChangeOffer.new(actor: provider_user,
                    application_choice: application_choice,
                    course_option: course_option,
                    conditions: new_conditions)
  end

  describe '#save!' do
    let(:provider_user) do
      create(:provider_user,
             :with_make_decisions,
             providers: [application_choice.current_course_option.provider])
    end
    let(:course_option) { course_option_for_provider(provider: application_choice.course_option.provider) }
    let(:new_conditions) { [Faker::Lorem.sentence] }
    let(:application_choice) do
      create(:application_choice, :with_offer, offer: { 'conditions' => ['DBS check'] })
    end

    describe 'if the actor is not authorised to perform this action' do
      let(:provider_user) do
        create(:provider_user,
               providers: [application_choice.current_course_option.provider])
      end

      it 'throws an exception' do
        expect {
          change_offer.save!
        }.to raise_error(
          ProviderAuthorisation::NotAuthorisedError,
          'You do not have the required user level permissions to make decisions on applications for this provider.',
        )
      end
    end

    describe 'if the new offer is identical to the current offer' do
      let(:change_offer) do
        ChangeOffer.new(actor: provider_user,
                        application_choice: application_choice,
                        course_option: application_choice.current_course_option,
                        conditions: ['DBS check'])
      end

      it 'raises an IdenticalOfferError' do
        expect {
          change_offer.save!
        }.to raise_error(
          ChangeOffer::IdenticalOfferError,
          'The new offer is identical to the current offer',
        )
      end
    end

    describe 'if the new offer is for a course not open on apply' do
      let(:course_option) do
        course_option_for_provider(
          provider: application_choice.course_option.provider,
          course: create(:course, provider: application_choice.course_option.provider, open_on_apply: false),
        )
      end

      it 'raises a Course Validation Error' do
        expect {
          change_offer.save!
        }.to raise_error(
          ChangeOffer::CourseValidationError,
          'is not open for applications via the Apply service',
        )
      end
    end

    describe 'if the .save returns false for any reason' do
      it 'throws an exception' do
        change_an_offer = instance_double(ChangeAnOffer)
        allow(ChangeAnOffer).to receive(:new).and_return(change_an_offer)
        allow(change_an_offer).to receive(:save).and_return(false)
        allow(change_an_offer).to receive(:errors).and_return({ base: [] })

        expect {
          change_offer.save!
        }.to raise_error('Unable to complete save on change_an_offer')
      end
    end

    describe 'if the provided details are correct' do
      let(:application_choice) { create(:application_choice, status: :awaiting_provider_decision) }
      let(:provider_user) do
        create(:provider_user,
               :with_make_decisions,
               providers: [application_choice.course_option.provider])
      end

      it 'then it executes the service without errors ' do
        set_declined_by_default = instance_double(SetDeclineByDefault, call: true)
        allow(SetDeclineByDefault)
            .to receive(:new).with(application_form: application_choice.application_form)
                    .and_return(set_declined_by_default)

        change_offer.save!

        expect(SetDeclineByDefault).to have_received(:new).with(application_form: application_choice.application_form)
      end
    end
  end
end
