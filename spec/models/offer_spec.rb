require 'rails_helper'

RSpec.describe Offer do
  let(:application_choice) { create(:application_choice) }

  describe 'course option validation' do
    it 'checks the course option is present' do
      offer = Offer.new(application_choice: application_choice, course_option: nil)

      expect(offer).not_to be_valid

      expect(offer.errors[:course_option]).to include('could not be found')
    end

    it 'checks the course option and conditions are different from the current option' do
      application_choice.update(offer: { 'conditions' => ['DBS check'] })
      offer = Offer.new(application_choice: application_choice, course_option: application_choice.offered_option, conditions: ['DBS check'])

      expect(offer).not_to be_valid

      expect(offer.errors[:base]).to include('The new offer is identical to the current offer')
    end

    it 'checks the course is open on apply' do
      new_course_option = create(:course_option, course: create(:course, open_on_apply: false))
      offer = Offer.new(application_choice: application_choice, course_option: new_course_option)

      expect(offer).not_to be_valid

      expect(offer.errors[:course_option]).to include('is not open for applications via the Apply service')
    end
  end

  describe 'conditions validation' do
    it 'checks there aren’t too many conditions' do
      offer = Offer.new(application_choice: application_choice, conditions: Array.new(21))

      expect(offer).not_to be_valid

      expect(offer.errors[:conditions]).to include('has over 20 elements')
    end
  end
end
