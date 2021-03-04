require 'rails_helper'

RSpec.describe UpdateAllNotificationPreferences do
  it 'raises an error if the value is not a boolean' do
    provider_user_notification = build(:provider_user_notification)

    expect { described_class.new(provider_user_notification, value: 'no').save! }.to raise_error(ArgumentError, 'Value has to be a boolean')
  end

  it 'updates notification preferences for all types of events' do
    provider_user_notification = create(:provider_user_notification)
    described_class.new(provider_user_notification, value: false).save!

    expect(provider_user_notification.application_received).to eq(false)
    expect(provider_user_notification.application_withdrawn).to eq(false)
    expect(provider_user_notification.application_rejected_by_default).to eq(false)
    expect(provider_user_notification.offer_accepted).to eq(false)
    expect(provider_user_notification.offer_declined).to eq(false)
  end
end
