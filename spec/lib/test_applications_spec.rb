require 'rails_helper'

RSpec.describe TestApplications do
  it 'generates an application with choices in the given states' do
    create(:course_option, course: create(:course, :open_on_apply))
    create(:course_option, course: create(:course, :open_on_apply))

    choices = TestApplications.create_application(states: %i[offer rejected])

    expect(choices.count).to eq(2)
  end

  it 'creates a realistic timeline' do
    courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.create_application(states: %i[enrolled], courses_to_apply_to: courses_we_want).first

    application_form = application_choice.application_form
    candidate = application_form.candidate
    expect(application_choice.created_at - candidate.created_at).to be >= 1.day
    expect(application_form.submitted_at - application_choice.created_at).to be >= 1.day
    expect(application_choice.offered_at - application_form.submitted_at).to be >= 1.day
    expect(application_choice.accepted_at - application_choice.offered_at).to be >= 1.day
    expect(application_choice.enrolled_at - application_choice.accepted_at).to be >= 1.day
  end

  it 'throws an exception if there aren’t enough courses to apply to' do
    expect {
      TestApplications.create_application(states: %i[offer])
    }.to raise_error(/Not enough distinct courses/)
  end

  it 'throws an exception if zero courses are specified per application' do
    expect {
      TestApplications.create_application(states: [])
    }.to raise_error(/You can't have zero courses per application/)
  end

  describe 'supplying our own courses' do
    it 'creates applications only for the supplied courses' do
      course_we_want = create(:course_option, course: create(:course, :open_on_apply)).course

      choices = TestApplications.create_application(states: %i[offer], courses_to_apply_to: [course_we_want])

      expect(choices.first.course).to eq(course_we_want)
    end

    it 'creates the right number of applications' do
      courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

      choices = TestApplications.create_application(states: %i[offer], courses_to_apply_to: courses_we_want)

      expect(choices.count).to eq(1)
    end
  end

  describe 'full work history' do
    it 'creates applications with work experience as well as explained and unexplained breaks' do
      create(:course_option, course: create(:course, :open_on_apply))

      choices = TestApplications.create_application(states: %i[awaiting_provider_decision])

      expect(choices.count).to eq(1)
      expect(choices.first.application_form.application_work_experiences.count).to eq(2)
      expect(choices.first.application_form.application_work_history_breaks.count).to eq(1)
    end
  end
end
