require 'rails_helper'

RSpec.describe ProviderUserNotificationPreferences do
  describe '#update_all_preferences' do
    let(:notification_preferences) { create(:provider_user_notification_preferences) }

    # it 'raises an error if the value is not a boolean' do
    #   expect { notification_preferences.update_all_preferences('no') }.to raise_error(ArgumentError, 'Value has to be a boolean')
    # end

    it 'updates all types of notification preferences' do
      described_class.new(provider_user_notification, value: false).save!

      NOTIFICATION_PREFERENCES.each do |type|
        expect(notification_preferences.send(type)).to eq(false)
      end
    end
  end

  describe '.notification_preference_exists?' do
    let(:current_provider_user) { create(:provider_user, providers: providers) }
    let(:provider_user) { create(:provider_user, providers: providers << non_visible_provider) }
    let(:non_visible_provider) { create(:provider, name: 'ZZZ') }
    let(:providers) do
      [
        create(:provider, name: 'ABC'),
        create(:provider, name: 'AAA'),
        create(:provider, name: 'ABB'),
      ]
    end

    before { current_provider_user.provider_permissions.update_all(manage_users: true) }

    it 'returns an ordered collection of provider permissions the current user can assign to other users' do
      expected_provider_names = described_class.possible_permissions(
        current_provider_user: current_provider_user,
        provider_user: provider_user,
      ).map { |p| p.provider.name }

      expect(expected_provider_names).to eq(%w[AAA ABB ABC])
    end
  end
end
