class NotificationsList
  attr_reader :event

  def self.for(application_choice, include_ratifying_provider: false, event: nil)
    if FeatureFlag.active?(:configurable_provider_notifications)
      raise 'Undefined type of notification event' if event.nil? || !ProviderUserNotification.method_defined?(event)

      return application_choice.provider.provider_users.joins(:provider_user_notification).where("#{event} IS true") if application_choice.accredited_provider.nil? || !include_ratifying_provider

      application_choice.provider.provider_users.or(application_choice.accredited_provider.provider_users)
        .joins(:provider_user_notification).where("#{event} IS true")
    else
      return application_choice.provider.provider_users.where(send_notifications: true) if application_choice.accredited_provider.nil? || !include_ratifying_provider

      application_choice.provider.provider_users.where(send_notifications: true).or(
        application_choice.accredited_provider.provider_users.where(send_notifications: true),
      )
    end
  end
end
