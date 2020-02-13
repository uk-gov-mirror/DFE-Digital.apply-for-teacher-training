module ProviderInterface
  class ApplicationChoicesController < ProviderInterfaceController
    def index
      @sort_order = params[:sort_order] ||= 'desc'
      @sort_by = params[:sort_by] ||= 'last-updated'

      column_mapping = {
        'name' => 'application_forms.last_name',
        'last-updated' => 'application_choices.updated_at',
        'course' => 'courses.name',
      }

      application_choices = GetApplicationChoicesForProviders.call(providers: current_provider_user.providers)
        .order(column_mapping[@sort_by] => @sort_order)

      @application_choices = application_choices
    end

    def show
      @application_choice = GetApplicationChoicesForProviders.call(providers: current_provider_user.providers)
        .find(params[:application_choice_id])
    end
  end
end
