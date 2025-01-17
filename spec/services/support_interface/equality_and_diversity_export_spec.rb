require 'rails_helper'

RSpec.describe SupportInterface::EqualityAndDiversityExport do
  describe 'documentation' do
    before do
      three_disabilities = {
        sex: 'female',
        ethnic_background: 'Kiwi',
        ethnic_group: 'Cantabrian',
        disabilities: %w[unexplained amnesia blind],
      }
      application_form = create(:completed_application_form, equality_and_diversity: three_disabilities)
      create(
        :application_choice,
        :with_structured_rejection_reasons,
        structured_rejection_reasons: {
          course_full_y_n: 'No',
          candidate_behaviour_y_n: 'Yes',
          candidate_behaviour_other: 'Persistent scratching',
          honesty_and_professionalism_y_n: 'Yes',
          honesty_and_professionalism_concerns: %w[references],
        },
        application_form: application_form,
      )
      create(:application_choice, :with_rejection, rejection_reason: 'Absence of English GCSE.', application_form: application_form)
    end

    it_behaves_like 'a data export'
  end

  describe '#data_for_export' do
    it 'returns an array of hashes containing equality and diversity data' do
      one_disability = {
        disabilities: %w[unexplained],
      }

      two_disabilities = {
        sex: 'female',
        ethnic_background: 'Kiwi',
        ethnic_group: 'Cantabrian',
        disabilities: %w[unexplained amnesia],
      }

      three_disabilities = {
        sex: 'female',
        ethnic_background: 'Kiwi',
        ethnic_group: 'Cantabrian',
        disabilities: %w[unexplained amnesia blind],
      }

      application_form_one = create(:completed_application_form, equality_and_diversity: two_disabilities)
      application_form_two = create(:completed_application_form, equality_and_diversity: one_disability)
      application_form_three = create(:completed_application_form, equality_and_diversity: three_disabilities)

      create(:completed_application_form, equality_and_diversity: nil)
      create(
        :application_choice,
        :with_structured_rejection_reasons,
        structured_rejection_reasons: {
          course_full_y_n: 'No',
          candidate_behaviour_y_n: 'Yes',
          candidate_behaviour_other: 'Persistent scratching',
          honesty_and_professionalism_y_n: 'Yes',
          honesty_and_professionalism_concerns: %w[references],
        },
        application_form: application_form_two,
      )

      create(:application_choice, :with_rejection, rejection_reason: 'Absence of English GCSE.', application_form: application_form_three)

      expect(described_class.new.data_for_export).to contain_exactly(
        {
          month: application_form_three.submitted_at&.strftime('%B'),
          recruitment_cycle_year: application_form_three.recruitment_cycle_year,
          sex: application_form_three.equality_and_diversity['sex'],
          ethnic_group: application_form_three.equality_and_diversity['ethnic_group'],
          ethnic_background: application_form_three.equality_and_diversity['ethnic_background'],
          application_status: 'Ended without success',
          application_choice_1_unstructured_rejection_reasons: 'Absence of English GCSE.',
          application_choice_2_unstructured_rejection_reasons: nil,
          application_choice_3_unstructured_rejection_reasons: nil,
          application_choice_1_structured_rejection_reasons: nil,
          application_choice_2_structured_rejection_reasons: nil,
          application_choice_3_structured_rejection_reasons: nil,
          disability_1: application_form_three.equality_and_diversity['disabilities'].first,
          disability_2: application_form_three.equality_and_diversity['disabilities'].second,
          disability_3: application_form_three.equality_and_diversity['disabilities'].last,
        },
        {
          month: application_form_one.submitted_at&.strftime('%B'),
          recruitment_cycle_year: application_form_one.recruitment_cycle_year,
          sex: application_form_one.equality_and_diversity['sex'],
          ethnic_group: application_form_one.equality_and_diversity['ethnic_group'],
          ethnic_background: application_form_one.equality_and_diversity['ethnic_background'],
          application_status: 'Have not started form',
          application_choice_1_unstructured_rejection_reasons: nil,
          application_choice_2_unstructured_rejection_reasons: nil,
          application_choice_3_unstructured_rejection_reasons: nil,
          application_choice_1_structured_rejection_reasons: nil,
          application_choice_2_structured_rejection_reasons: nil,
          application_choice_3_structured_rejection_reasons: nil,
          disability_1: application_form_one.equality_and_diversity['disabilities'].first,
          disability_2: application_form_one.equality_and_diversity['disabilities'].last,
        },
        {
          month: application_form_two.submitted_at&.strftime('%B'),
          recruitment_cycle_year: application_form_two.recruitment_cycle_year,
          sex: application_form_two.equality_and_diversity['sex'],
          ethnic_group: application_form_two.equality_and_diversity['ethnic_group'],
          ethnic_background: application_form_two.equality_and_diversity['ethnic_background'],
          application_status: 'Ended without success',
          application_choice_1_unstructured_rejection_reasons: nil,
          application_choice_2_unstructured_rejection_reasons: nil,
          application_choice_3_unstructured_rejection_reasons: nil,
          application_choice_1_structured_rejection_reasons: 'Something you did, Honesty and professionalism',
          application_choice_2_structured_rejection_reasons: nil,
          application_choice_3_structured_rejection_reasons: nil,
          disability_1: application_form_two.equality_and_diversity['disabilities'].first,
        },
      )
    end
  end
end
