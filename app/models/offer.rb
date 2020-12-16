class Offer
  include ActiveModel::Model

  attr_accessor :application_choice, :conditions, :course_option

  MAX_CONDITIONS_COUNT = 20
  MAX_CONDITION_LENGTH = 255

  validates :course_option, presence: true
  validate :validate_offer_is_not_identical
  validate :validate_course_option_is_open_on_apply
  validate :validate_conditions_max_length
  validate :application_choice_can_receive_offer

  def save!
    raise unless valid?

    ActiveRecord::Base.transaction do
      if changing_existing_offer?
        save_as_changed_offer!
      else
        save_as_new_offer!
      end

      SetDeclineByDefault.new(application_form: application_choice.application_form).call
    end
  end

  def identical_to_existing_offer?
    course_option.present? && \
      course_option == application_choice.offered_option && \
      application_choice.offer['conditions'] == conditions
  end

private

  def save_as_new_offer
    application_choice.status = 'offer'
    application_choice.offered_course_option = course_option
    application_choice.offer = { 'conditions' => conditions }
    application_choice.offered_at = Time.zone.now
    application_choice.save!
  end

  def save_as_changed_offer!
    now = Time.zone.now
    attributes = {
      offered_course_option: course_option,
      offer_changed_at: now,
    }
    attributes[:offer] = { 'conditions' => conditions } if conditions
    application_choice.update! attributes
  end

  def changing_existing_offer?
    application_choice.offered_option.present?
  end

  def validate_offer_is_not_identical
    if identical_to_existing_offer?
      errors.add(:base, 'The new offer is identical to the current offer')
    end
  end

  def validate_course_option_is_open_on_apply
    if course_option.present? && !course_option.course.open_on_apply
      errors.add(:course_option, :not_open_on_apply)
    end
  end

  def validate_conditions_max_length
    return if offer_conditions.is_a?(Array) && offer_conditions.count <= MAX_CONDITIONS_COUNT

    errors.add(:offer_conditions, "has over #{MAX_CONDITIONS_COUNT} elements")
  end

  def application_choice_can_receive_offer
    unless ApplicationStateChange.new(application_choice).can_make_offer?
      errors.add(
        :base,
        I18n.t('activerecord.errors.models.application_choice.attributes.status.invalid_transition'),
      )
    end
  end
end
