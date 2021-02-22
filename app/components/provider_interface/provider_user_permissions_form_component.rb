module ProviderInterface
  class ProviderUserPermissionsFormComponent < ViewComponent::Base
    attr_reader :form_model, :form_method, :form_url, :provider, :submit_text

    def initialize(permissions_form_model:, form_method:, form_url:, submit_text:)
      @form_model = permissions_form_model
      @form_method = form_method
      @form_url = form_url
      @provider = permissions_form_model.provider
      @submit_text = submit_text
    end
  end
end
