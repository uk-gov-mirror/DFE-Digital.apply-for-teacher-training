module ProviderInterface
  class ProviderUserPermissionsForm
    include ActiveModel::Model

    attr_accessor :view_applications_only, :provider, :provider_user
    attr_writer :permissions

    validates :provider, :provider_user, presence: true
    validates :view_applications_only, presence: { message: 'Choose whether this user has extra permissions' }
    validate :at_least_one_extra_permission_is_set, unless: :view_applications_only

    def self.build_from_model(permissions_model)
      return unless permissions_model

      new_form = new(provider: permissions_model.provider, provider_user: permissions_model.provider_user)

      ProviderPermissions::VALID_PERMISSIONS.each do |permission_name|
        if permissions_model.send(permission_name)
          new_form.permissions << permission_name.to_s
        end
      end

      new_form.view_applications_only = new_form.permissions.none?

      new_form
    end

    def self.build_from_params(params)
      return unless params

      new_form = new(provider: params[:provider], provider_user: params[:provider_user])

      view_applications_only = ActiveModel::Type::Boolean.new.cast(params[:view_applications_only])
      new_form.view_applications_only = view_applications_only

      return new_form if view_applications_only

      selected_permissions = params.fetch(:permissions, []).select(&:present?)
      new_form.permissions = ProviderPermissions::VALID_PERMISSIONS.map(&:to_s) & selected_permissions

      new_form
    end

    def permissions
      @permissions ||= []
    end

  private

    def at_least_one_extra_permission_is_set
      if permissions.none?
        errors[:permissions] << 'Select extra permissions'
      end
    end
  end
end
