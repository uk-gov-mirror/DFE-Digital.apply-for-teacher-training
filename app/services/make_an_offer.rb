class MakeAnOffer
  include ActiveModel::Model

  validate :offer_is_valid

  def initialize(actor:, offer:)
    @offer = offer
    @auth = ProviderAuthorisation.new(actor: actor)
  end

  def save
    @auth.assert_can_make_decisions!(application_choice: offer.application_choice, course_option_id: @offer.course_option.id)
    if valid?
      offer.save!

      SendNewOfferEmailToCandidate.new(application_choice: @offer.application_choice).call
      StateChangeNotifier.call(:make_an_offer, application_choice: @offer.application_choice)

      true
    else
      false
    end
  end

private

  def offer_is_valid
    if offer.invalid?
      offer.errors.each do |field, error|
        errors.add(field, error)
      end
    end
  end
end
