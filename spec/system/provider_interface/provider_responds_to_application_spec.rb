require 'rails_helper'

RSpec.feature 'Provider responds to application' do
  include CourseOptionHelpers
  include DfESignInHelpers
  include ProviderUserPermissionsHelper

  let(:course_option) { course_option_for_provider_code(provider_code: 'ABC') }

  let(:application_awaiting_provider_decision) do
    create(:submitted_application_choice,
           :with_completed_application_form,
           status: 'awaiting_provider_decision',
           course_option: course_option)
  end

  let(:application_rejected) do
    create(:submitted_application_choice,
           status: 'rejected',
           rejected_at: Time.zone.now,
           course_option: course_option)
  end

  scenario 'Provider can respond to an application' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_i_am_permitted_to_see_applications_for_my_provider
    and_i_am_permitted_to_make_decisions_on_applications_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_a_application_with_status_awaiting_provider_decision
    then_i_can_see_its_status application_awaiting_provider_decision
    and_i_can_respond_to_the_application

    when_i_click_to_respond_to_the_application
    then_i_can_see_the_course_details
    and_i_am_given_the_option_to_make_an_offer
    and_i_am_given_the_option_to_reject_the_application
  end

  scenario 'Provider cannot respond to application currently rejected' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_i_am_permitted_to_see_applications_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_a_application_with_status_rejected
    then_i_can_see_its_status application_rejected
    and_i_cannot_respond_to_the_application
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_i_am_permitted_to_see_applications_for_my_provider
    provider_user_exists_in_apply_database
  end

  def and_i_am_permitted_to_make_decisions_on_applications_for_my_provider
    permit_make_decisions!
  end

  def when_i_visit_a_application_with_status_awaiting_provider_decision
    visit provider_interface_application_choice_path(
      application_awaiting_provider_decision.id,
    )
  end

  def when_i_visit_a_application_with_status_rejected
    visit provider_interface_application_choice_path(
      application_rejected.id,
    )
  end

  def then_i_can_see_its_status(application)
    if application.status == 'awaiting_provider_decision'
      expect(page).to have_content 'Submitted'
    elsif application.status == 'rejected'
      expect(page).to have_content 'Rejected'
    end
  end

  def and_i_can_respond_to_the_application
    expect(page).to have_content 'Make decision'
  end

  def and_i_cannot_respond_to_the_application
    expect(page).not_to have_content 'Make decision'
  end

  def when_i_click_to_respond_to_the_application
    click_on 'Make decision'
  end

  def then_i_can_see_the_course_details
    expect(page).to have_content 'Course applied for'
  end

  def and_i_am_given_the_option_to_make_an_offer
    expect(page).to have_content 'Make an offer'
  end

  def and_i_am_given_the_option_to_reject_the_application
    expect(page).to have_content 'Reject application'
  end
end
