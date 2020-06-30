module ProviderInterface
  class ApplicationStatusTagComponentPreview < ViewComponent::Preview
    ApplicationStateChange.valid_states.each do |state_name|
      define_method state_name do
        render ProviderInterface::ApplicationStatusTagComponent.new(application_choice: FactoryBot.build(:application_choice, status: state_name))
      end
    end
  end
end
