require 'rails_helper'

RSpec.describe CandidateInterface::ApplicationCompleteContentComponent do
  let(:reject_by_default_limit) { TimeLimitConfig.limits_for(:reject_by_default).first.limit }
  let(:reject_by_default_at) { reject_by_default_limit.business_days.from_now }
  let(:decline_by_default_limit) { TimeLimitConfig.limits_for(:decline_by_default).first.limit }
  let(:decline_by_default_at) { decline_by_default_limit.business_days.from_now }

  around do |example|
    Timecop.freeze do
      example.run
    end
  end

  context 'when the application is waiting for a decision from providers' do
    it 'renders the respond date for providers' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[awaiting_provider_decision])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).not_to include(t('application_complete.dashboard.edit_link'))
      expect(render_result.text).to include(t('application_complete.dashboard.providers_respond_by', date: reject_by_default_at.to_s(:govuk_date)))
    end
  end

  context 'when the application has an offer from a provider' do
    it 'renders with some providers have made a decision content' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[offer awaiting_provider_decision])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.some_provider_decisions_made'))
      expect(render_result.text).to include(t('application_complete.dashboard.providers_respond_by', date: reject_by_default_at.to_s(:govuk_date)))
    end
  end

  context 'when the application has all decisions from providers' do
    let(:remaining_days) { (decline_by_default_at.to_date - Date.current).to_i }

    it 'renders with all providers have made a decision content if all offers' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[offer offer])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.all_provider_decisions_made', count: 2))
      expect(render_result.text).to include(t('application_complete.dashboard.candidate_respond_by', remaining_days: remaining_days, date: decline_by_default_at.to_s(:govuk_date)))
    end

    it 'renders with all providers have made a decision content if an offer and rejected' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[offer rejected])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.all_provider_decisions_made', count: 2))
      expect(render_result.text).to include(t('application_complete.dashboard.candidate_respond_by', remaining_days: remaining_days, date: decline_by_default_at.to_s(:govuk_date)))
    end

    it 'renders when all offers have been withdrawn' do
      application_form = build_stubbed(:application_form, application_choices: [
        build_stubbed(:application_choice, application_form: application_form, status: :withdrawn),
      ])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.all_withdrawn', count: 1))
    end

    it 'renders when one offer has been withdrawn and one offered' do
      application_form = build_stubbed(:application_form, application_choices: [
        build_stubbed(:application_choice, application_form: application_form, status: :withdrawn),
        build_stubbed(:application_choice, application_form: application_form, status: :offer, decline_by_default_at: 1.day.from_now),
      ])

      allow(ApplicationDates).to receive(:new).with(application_form).and_return(
        instance_double(ApplicationDates, decline_by_default_at: 1.day.from_now),
      )

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.all_provider_decisions_made', count: 2))
    end

    it 'renders when the only offer has been rejected' do
      application_form = build_stubbed(:application_form, application_choices: [
        build_stubbed(:application_choice, application_form: application_form, status: :rejected),
      ])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.all_provider_decisions_made', count: 1))
    end
  end

  context 'when the application has accepted an offer' do
    it 'renders with accepted offer content' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[pending_conditions declined])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.accepted_offer'))
    end
  end

  context 'when the application is recruited' do
    it 'renders with recruited content' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[recruited declined])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.recruited'))
    end
  end

  context 'when the application is deferred' do
    it 'renders with deferred content' do
      stub_application_dates_with_form
      application_form = create_application_form_with_course_choices(statuses: %w[offer_deferred declined])

      render_result = render_inline(described_class.new(application_form: application_form))

      expect(render_result.text).to include(t('application_complete.dashboard.deferred'))
    end
  end

  def stub_application_dates_with_form
    application_dates = instance_double(
      ApplicationDates,
      reject_by_default_at: reject_by_default_at,
      decline_by_default_at: decline_by_default_at,
    )
    allow(ApplicationDates).to receive(:new).and_return(application_dates)
  end

  def create_application_form_with_course_choices(statuses:)
    application_form = build_stubbed(:application_form)
    application_choices = statuses.map do |status|
      build_stubbed(
        :application_choice,
        application_form: application_form,
        status: status,
        reject_by_default_at: reject_by_default_at,
      )
    end

    allow(application_form).to receive(:application_choices).and_return(application_choices)

    application_form
  end
end
