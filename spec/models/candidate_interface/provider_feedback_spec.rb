require 'rails_helper'

RSpec.describe CandidateInterface::ProviderFeedback do
  describe '.from_previous_applications' do
    context 'when given an unsupported section' do
      it 'raises an error' do
        application_form = build(:application_form)

        expect {
          CandidateInterface::ProviderFeedback.from_previous_applications(application_form, :juggling_skills)
        }.to raise_error(CandidateInterface::ProviderFeedback::UnsupportedSectionError)
      end
    end

    context 'when no previous application' do
      it 'returns an empty array' do
        application_form = create(:application_form)
        expect(
          described_class.from_previous_applications(application_form, :becoming_a_teacher),
        ).to eq []
      end
    end

    it 'returns provider feedback from previous applications' do
      previous_application_form1 = create(:application_form)
      choice1 = create(:application_choice, :with_structured_rejection_reasons, application_form: previous_application_form1)
      choice2 = create(:application_choice, :with_structured_rejection_reasons, application_form: previous_application_form1)
      previous_application_form2 = apply_again!(previous_application_form1)
      choice3 = create(:application_choice, :with_structured_rejection_reasons, application_form: previous_application_form2)

      %w[Bad Good Amazing].zip([choice1, choice2, choice3]).each do |feedback, choice|
        choice.update!(structured_rejection_reasons: choice.structured_rejection_reasons.merge(quality_of_application_personal_statement_what_to_improve: feedback))
      end

      current_application_form = apply_again!(previous_application_form2)

      feedback = described_class.from_previous_applications(current_application_form, :becoming_a_teacher)

      expect(feedback).to match_array [
        described_class.new(choice3.provider.name, :becoming_a_teacher, 'Amazing'),
        described_class.new(choice2.provider.name, :becoming_a_teacher, 'Good'),
        described_class.new(choice1.provider.name, :becoming_a_teacher, 'Bad'),
      ]
    end

  private

    def apply_again!(application_form)
      DuplicateApplication.new(application_form, target_phase: :apply_2).duplicate
    end
  end
end
