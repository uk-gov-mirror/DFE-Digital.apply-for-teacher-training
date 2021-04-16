require 'rails_helper'

RSpec.feature 'Candidate with unsuccessful application can review feedback when applying again' do
  include CandidateHelper

  scenario 'Apply again and review feedback' do
    given_i_am_signed_in_as_a_candidate
    and_i_have_an_unsuccessful_application_with_rejection_reasons
    when_i_apply_again
    then_becoming_a_teacher_needs_review
    and_i_can_review_becoming_a_teacher
  end

  def given_i_am_signed_in_as_a_candidate
    @candidate = create(:candidate)
    login_as(@candidate)
  end

  def and_i_have_an_unsuccessful_application_with_rejection_reasons
    application = create(:completed_application_form, candidate: @candidate)
    create(:application_choice, :with_structured_rejection_reasons, application_form: application)
  end

  def when_i_apply_again

  end
end
