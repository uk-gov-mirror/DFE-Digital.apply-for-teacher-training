require 'rails_helper'

RSpec.describe ReinstatePendingConditions do
  let(:provider_user) { create(:provider_user, :with_provider, :with_make_decisions) }
  let(:provider) { provider_user.providers.first }
  let(:original_course) { create(:course, :open_on_apply, :previous_year_but_still_available, provider: provider) }
  let(:previous_course_option) { create(:course_option, course: original_course) }
  let(:new_course_option) { create(:course_option, course: original_course.in_next_cycle) }
  let(:application_choice) { create(:application_choice, :with_deferred_offer, course_option: previous_course_option) }

  def service
    ReinstatePendingConditions.new(actor: provider_user, application_choice: application_choice, course_option: new_course_option)
  end

  it 'changes application status to \'pending_conditions\'' do
    expect { service.save }.to change(application_choice, :status).to('pending_conditions')
  end

  it 'changes current_course_option_id for the application choice' do
    expect { service.save }.to change(application_choice, :current_course_option_id)
  end

  it 'sets recruited_at to nil if conditions are no longer met' do
    application_choice.update(
      status_before_deferral: 'recruited',
      recruited_at: application_choice.accepted_at + 7.days,
    )

    Timecop.freeze do
      expect { service.save }.to change(application_choice, :recruited_at).to(nil)
    end
  end

  describe 'course option validation' do
    it 'checks the course option is present' do
      reinstate = ReinstatePendingConditions.new(actor: provider_user, application_choice: application_choice, course_option: nil)

      expect(reinstate).not_to be_valid

      expect(reinstate.errors[:course_option]).to include('could not be found')
    end

    it 'checks the course is open on apply' do
      new_course_option = create(:course_option, course: create(:course, provider: provider, open_on_apply: false))
      reinstate = ReinstatePendingConditions.new(actor: provider_user, application_choice: application_choice, course_option: new_course_option)

      expect(reinstate).not_to be_valid

      expect(reinstate.errors[:course_option]).to include('is not open for applications via the Apply service')
    end

    it 'checks course option matches the current RecruitmentCycle' do
      reinstate = ReinstatePendingConditions.new(actor: provider_user, application_choice: application_choice, course_option: previous_course_option)

      expect(reinstate).not_to be_valid

      expect(reinstate.errors[:course_option]).to include('does not belong to the current cycle')
    end
  end
end
