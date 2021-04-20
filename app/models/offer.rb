class Offer
  attr_reader :application_choice

  delegate :declined_at, :declined_by_default,
           :accepted_at, :recruited_at, :conditions_not_met_at,
           to: :application_choice

  def initialize(application_choice:)
    @application_choice = application_choice
  end

  def conditions
    offer = application_choice.read_attribute(:offer)

    offer['conditions'] if offer.present?
  end

  def created_at
    application_choice.offered_at
  end

  def updated_at
    application_choice.offer_changed_at
  end

  def withdrawal_reason
    application_choice.offer_withdrawal_reason
  end

  def withdrawn_at
    application_choice.offer_withdrawn_at
  end

  def deferred_at
    application_choice.offer_deferred_at
  end

  def course_option
    application_choice.offered_course_option || application_choice.course_option
  end

  def provider
    course_option.provider
  end

  def course
    course_option.course
  end

  def site
    course_option.site
  end

  def recruitment_cycle
    course.recruitment_cycle_year
  end

  def declined_by_default?
    declined_by_default
  end
end
