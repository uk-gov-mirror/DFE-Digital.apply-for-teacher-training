class MakeOffer
  attr_reader :auth, :application_choice, :course_option, :conditions

  def initialize(actor:,
                 application_choice:,
                 course_option:,
                 conditions: [])
    @auth = ProviderAuthorisation.new(actor: actor)
    @application_choice = application_choice
    @course_option = course_option
    @conditions = conditions
  end

  def save!
    auth.assert_can_make_decisions!(application_choice: application_choice, course_option_id: course_option.id)

    if offer.valid?
      ActiveRecord::Base.transaction do
        ApplicationStateChange.new(application_choice).make_offer!

        application_choice.offered_course_option = course_option
        application_choice.current_course_option = course_option
        application_choice.offer = { 'conditions' => conditions }
        application_choice.offered_at = Time.zone.now
        application_choice.save!
      end

      SetDeclineByDefault.new(application_form: application_choice.application_form).call
      SendNewOfferEmailToCandidate.new(application_choice: application_choice).call
    else
      raise offer.errors.full_messages.join(' ')
    end
  end

private

  def offer
    @offer ||= OfferValidations.new(course_option: course_option,
                                    conditions: conditions)
  end
end
