require 'rails_helper'

RSpec.describe 'Candidate can carry over unsuccessful application to a new recruitment cycle between cycles' do
  include CycleTimetableHelper

  around do |example|
    Timecop.freeze(mid_cycle) do
      example.run
    end
  end

  scenario 'when an unsuccessful candidate returns in the next recruitment cycle they can re-apply by carrying over their original application' do
    given_i_am_signed_in
    and_i_have_an_application_with_a_rejection

    when_the_apply2_deadline_passes
    and_i_visit_my_application_complete_page
    and_i_click_on_apply_again
    and_i_click_on_start_now

    then_i_can_see_application_details
    and_i_can_see_that_no_courses_are_selected_and_i_cannot_add_any_yet

    when_the_next_cycle_opens
    and_i_visit_my_application_complete_page
    then_i_can_add_course_choices
  end

  def given_i_am_signed_in
    @candidate = create(:candidate)
    login_as(@candidate)
  end

  def and_i_have_an_application_with_a_rejection
    @application_form = create(:completed_application_form, :with_completed_references, candidate: @candidate)
    create(:application_choice, :with_rejection, application_form: @application_form)
  end

  def when_the_apply2_deadline_passes
    Timecop.safe_mode = false
    Timecop.travel(after_apply_2_deadline)
  ensure
    Timecop.safe_mode = true
  end

  def and_i_visit_my_application_complete_page
    logout
    login_as(@candidate)
    visit candidate_interface_application_complete_path
  end

  def and_i_click_on_apply_again
    expect(page).to have_content "Courses for the #{RecruitmentCycle.cycle_name(RecruitmentCycle.next_year)} academic year are now closed"
    click_link 'apply again'
  end

  def and_i_click_on_start_now
    expect(page).to have_content "You can submit your application from #{EndOfCycleTimetable.apply_reopens.to_s(:govuk_date)}."
    expect(page).to have_content 'Your courses have been removed. You can add them again later.'
    click_button 'Apply again'
  end

  def and_i_click_go_to_my_application_form
    click_link 'Go to your application form'
  end

  def then_i_can_see_application_details
    expect(page).to have_content('Personal information Completed')
    click_link 'Personal information'
    expect(page).to have_content(@application_form.full_name)
    click_button t('continue')
  end

  def and_i_can_see_that_no_courses_are_selected_and_i_cannot_add_any_yet
    expect(page).to have_content "You’ll be able to find courses in #{(EndOfCycleTimetable.find_reopens - Time.zone.today).to_i} days (#{EndOfCycleTimetable.find_reopens.to_s(:govuk_date)}). You can keep making changes to the rest of your application until then."
    expect(page).not_to have_link 'Course choice'
  end

  def when_the_next_cycle_opens
    Timecop.safe_mode = false
    Timecop.travel(after_apply_reopens)
  ensure
    Timecop.safe_mode = true
  end

  def then_i_can_add_course_choices
    expect(page).to have_content('Choose your courses Incomplete')
    click_link 'Choose your courses'
    expect(page).to have_content 'You can apply for up to 3 courses'
  end
end
