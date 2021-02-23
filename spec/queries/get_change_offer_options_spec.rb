require 'rails_helper'

RSpec.describe GetChangeOfferOptions do
  include CourseOptionHelpers

  let(:provider_user) { create(:provider_user, :with_two_providers) }
  let(:course_option) { course_option_for_provider_code(provider_code: provider_user.providers.first.code) }
  let(:application_choice) { create(:application_choice, :with_offer, course_option: course_option) }

  let(:service) do
    GetChangeOfferOptions.new(
      application_choice: application_choice,
      user: provider_user
    )
  end

  describe '#available_providers' do
    it 'returns a list of all providers' do
      expect(service.available_providers.count).to eq(2)
    end
  end
end
