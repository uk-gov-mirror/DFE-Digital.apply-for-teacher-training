require 'rails_helper'
RSpec.describe OfferValidations, type: :model do
  subject(:offer) { OfferValidations.new(course_option: course_option, conditions: conditions) }

  let(:course_option) { create(:course_option, course: course) }
  let(:course) { create(:course, :open_on_apply) }
  let(:conditions) { [] }

  context 'validations' do
    it { is_expected.to validate_presence_of(:course_option) }

    describe '#course_option_open_on_apply' do
      context 'when no course_option' do
        let(:course_option) { nil }

        it 'does not add a :not_open_on_apply error' do
          offer.valid?

          expect(offer.errors[:course_option]).not_to contain_exactly('is not open for applications via the Apply service')
        end
      end

      context 'when open on apply' do
        let(:course) { create(:course, :ucas_only) }

        it 'adds a :not_open_on_apply error' do
          expect(offer).to be_invalid

          expect(offer.errors[:course_option]).to contain_exactly('is not open for applications via the Apply service')
        end
      end
    end

    describe '#conditions_count' do
      context 'when more than MAX_CONDITIONS_COUNT' do
        let(:conditions) { (OfferValidations::MAX_CONDITIONS_COUNT + 1).times.map { Faker::Coffee.blend_name } }

        it 'adds a :too_many error' do
          expect(offer).to be_invalid

          expect(offer.errors[:conditions]).to contain_exactly("has over #{OfferValidations::MAX_CONDITIONS_COUNT} conditions")
        end
      end
    end

    describe '#conditions_length' do
      context 'when any conditions are more than 255 characters long' do
        let(:conditions) do
          [Faker::Lorem.paragraph_by_chars(number: 256),
           Faker::Lorem.paragraph_by_chars(number: 254),
           Faker::Lorem.paragraph_by_chars(number: 256)]
        end

        it 'adds a :too_long error' do
          expect(offer).to be_invalid

          expect(offer.errors[:conditions]).to contain_exactly('1 must be 255 characters or fewer', '3 must be 255 characters or fewer')
        end
      end
    end
  end
end
