class UpdateAllNotificationPreferences
  attr_reader :provider_user_notification, :value

  def initialize(provider_user_notification, value:)
    @provider_user_notification = provider_user_notification
    @value = value
  end

  def save!
    raise ArgumentError, 'Value has to be a boolean' unless value.in? ['true', 'false', true, false]

    provider_user_notification.update!(
      application_received: value,
      application_withdrawn: value,
      application_rejected_by_default: value,
      offer_accepted: value,
      offer_declined: value,
    )
  end
end
