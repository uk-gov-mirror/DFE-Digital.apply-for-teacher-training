require 'rails_helper'

RSpec.describe 'Candidate can see their structured reasons for rejection when reviewing their application' do
  scenario 'when a candidate visits their apply again application form they can see apply1 rejection reasons' do
    given_i_am_signed_in
    and_structured_rejection_reasons_feature_is_active
    and_i_have_an_apply1_application_with_2_rejections

    when_i_visit_my_application_complete_page
    then_i_can_see_my_rejection_reasons

    when_i_apply_again
    then_i_can_see_rejection_reasons_from_the_earlier_application
    and_i_should_see_unsuccessful_status
    and_i_should_not_see_a_link_to_the_course_on_find
  end

  def given_i_am_signed_in
    @candidate = create(:candidate)
    login_as(@candidate)
  end

  def and_structured_rejection_reasons_feature_is_active
    FeatureFlag.activate(:structured_reasons_for_rejection)
  end

  def and_i_have_an_apply1_application_with_2_rejections
    @application_form = create(:completed_application_form, :with_completed_references, candidate: @candidate)
    @application_choice_with_reasons = create(:application_choice, :with_structured_rejection_reasons, application_form: @application_form)
    @application_choice = create(:application_choice, :with_rejection, application_form: @application_form)
  end

  def when_i_visit_my_application_complete_page
    visit candidate_interface_application_complete_path
  end

  def then_i_can_see_my_rejection_reasons
    expect(page).to have_content('Quality of application')
    expect(page).to have_content('Use a spellchecker.')
  end

  def when_i_apply_again
    click_on 'Do you want to apply again?'
    click_on 'Start now'
    click_on 'Go to your application form'
  end

  def then_i_can_see_rejection_reasons_from_the_earlier_application
    expect(page).to have_content('Quality of application')
    expect(page).to have_content('Use a spellchecker.')
  end

  def and_i_should_see_unsuccessful_status
    expect(page).to have_content('Unsuccessful')
  end

  def and_i_should_not_see_a_link_to_the_course_on_find
    course_name = @application_choice_with_reasons.offered_course.name_and_code
    expect(page).to have_content(course_name)
    expect(page).not_to have_link(course_name)
  end
end
