module ProviderInterface
  class InterviewsController < ProviderInterfaceController
    before_action :set_application_choice

    def new
      @new_interview_form = InterviewForm.new
    end

    def check
      @new_interview_form = InterviewForm.new(new_interview_params)

      render :new unless @new_interview_form.valid?
    end

    def create
      @new_interview_form = InterviewForm(new_interview_params)
      @new_interview_form.save
      redirect_to provider_interface_application_choice_path(@application_choice)
    end

  private

    def make_decisions_permission_orgs
      @_make_decisions_permission_orgs ||= begin
        application_choice_providers = [@application_choice.provider, @application_choice.accredited_provider].compact
        current_user_providers = current_provider_user
          .provider_permissions.includes([:provider])
          .make_decisions
        .map(&:provider)

        current_user_providers.select { |provider| application_choice_providers.include?(provider)  }
      end
    end
    helper_method :make_decisions_permission_orgs

    def new_interview_params
      params
        .require(:provider_interface_new_interview_form)
        .permit(:'date(3i)', :'date(2i)', :'date(1i)', :time, :location, :additional_details)
        .transform_keys { |key| date_field_to_attribute(key) }
        .transform_values(&:strip)
        .merge(application_choice: @application_choice)
    end

    def date_field_to_attribute(key)
      case key
      when 'date(3i)' then 'day'
      when 'date(2i)' then 'month'
      when 'date(1i)' then 'year'
      else key
      end
    end
  end
end
