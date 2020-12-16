class Offer
  include ActiveModel::Model

  attr_accessor :application_choice, :conditions, :course_option

  validates :course_option, presence: true
  validate :validate_offer_is_not_identical
  validate :validate_course_option_is_open_on_apply

  def save!
    if changing_existing_offer?
      save_as_changed_offer!
    else
      raise 'save_as_new_offer! not implemented yet!'
    end
  end

  def identical_to_existing_offer?
    course_option.present? && \
      course_option == application_choice.offered_option && \
      application_choice.offer['conditions'] == conditions
  end

private

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
end
