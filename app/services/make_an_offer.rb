class MakeAnOffer
  attr_accessor :standard_conditions
  attr_accessor :further_conditions0, :further_conditions1, :further_conditions2, :further_conditions3
  attr_accessor :auth

  include ActiveModel::Validations

  MAX_CONDITIONS_COUNT = 20
  MAX_CONDITION_LENGTH = 255
  STANDARD_CONDITIONS = ['Fitness to Teach check', 'Disclosure and Barring Service (DBS) check'].freeze

  validate :validate_conditions_max_length
  validate :validate_further_conditions

  def initialize(
    actor:,
    application_choice:,
    course_option_id: nil,
    offer_conditions: nil,
    standard_conditions: STANDARD_CONDITIONS,
    further_conditions: {}
  )
    @auth = ProviderAuthorisation.new(actor: actor)
    @application_choice = application_choice
    @course_option_id = course_option_id
    @offer_conditions = offer_conditions
    @standard_conditions = standard_conditions
    further_conditions.each { |key, value| self.send("#{key}=", value) }
  end

  def save
    return unless valid?

    @auth.assert_can_make_offer!(application_choice: application_choice, course_option_id: @course_option_id)

    ApplicationStateChange.new(application_choice).make_offer!
    application_choice.offered_course_option = offered_course_option
    application_choice.offer = { 'conditions' => offer_conditions }

    application_choice.offered_at = Time.zone.now
    application_choice.save!

    SetDeclineByDefault.new(application_form: application_choice.application_form).call
    SendNewOfferEmailToCandidate.new(application_choice: @application_choice).call
    StateChangeNotifier.call(:make_an_offer, application_choice: application_choice)
  rescue Workflow::NoTransitionAllowed
    errors.add(
      :base,
      I18n.t('activerecord.errors.models.application_choice.attributes.status.invalid_transition'),
    )
    false
  end

  def offer_conditions
    @offer_conditions ||= [
      standard_conditions,
      further_conditions,
    ].flatten.reject(&:blank?)
  end

private

  attr_reader :application_choice

  def offered_course_option
    return nil unless @course_option_id && @course_option_id != application_choice.course_option.id

    CourseOption.find @course_option_id
  end

  def further_conditions
    [
      further_conditions0,
      further_conditions1,
      further_conditions2,
      further_conditions3,
    ]
  end

  def validate_further_conditions
    return if further_conditions.blank?

    further_conditions.each_with_index do |value, index|
      if value && value.length > MAX_CONDITION_LENGTH
        errors.add(
          "further_conditions#{index}",
          I18n.t(
            'activemodel.errors.models.support_interface/new_offer_form.attributes.further_conditions.too_long',
            name: I18n.t("activemodel.attributes.support_interface/new_offer.further_conditions#{index}"),
            limit: MAX_CONDITION_LENGTH,
          ),
        )
      end
    end
  end

  def validate_conditions_max_length
    return if offer_conditions.is_a?(Array) && offer_conditions.count <= MAX_CONDITIONS_COUNT

    errors.add(:offer_conditions, "has over #{MAX_CONDITIONS_COUNT} elements")
  end
end
