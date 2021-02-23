module ProviderInterface
  class ProviderUserPermissionsForm
    include ActiveModel::Model

    attr_accessor :model,
                  :manage_organisations,
                  :manage_users,
                  :make_decisions,
                  :view_safeguarding_information,
                  :view_diversity_information,
                  :view_applications_only

    delegate :provider, to: :model
    delegate :provider_user, to: :model
    delegate :id, to: :provider, prefix: true

    validates :model, presence: true
    validate :at_least_one_extra_permission_is_set_if_necessary

    def self.from(permissions_model)
      return unless permissions_model

      new_form = new(model: permissions_model)

      if permissions_model.view_applications_only?
        new_form.view_applications_only = true
      else
        new_form.view_applications_only = false
        ProviderPermissions::VALID_PERMISSIONS.each do |permission_name|
          new_form.send("#{permission_name}=", permissions_model.send(permission_name))
        end
      end

      new_form
    end

    def update_from_params(hash)
      self.view_applications_only = ActiveModel::Type::Boolean.new.cast(hash[:view_applications_only])

      selected_permissions = hash[:permissions].select(&:present?)

      ProviderPermissions::VALID_PERMISSIONS.each do |permission_name|
        permission_value = view_applications_only ? false : selected_permissions.include?(permission_name.to_s)
        send("#{permission_name}=", permission_value)
      end
    end

    def permissions
      ProviderPermissions::VALID_PERMISSIONS.select { |permission| send(permission) }
    end

    def save
      if valid?
        ProviderPermissions::VALID_PERMISSIONS.each do |permission_name|
          @model.send("#{permission_name}=", send(permission_name))
        end

        @model.save
      end
    end

  private

    def at_least_one_extra_permission_is_set_if_necessary
      return if view_applications_only

      selected_extra_permissions = ProviderPermissions::VALID_PERMISSIONS.map { |permission| send(permission) }
      if selected_extra_permissions.none?
        errors[:permissions] << 'Select extra permissions'
      end
    end
  end
end
