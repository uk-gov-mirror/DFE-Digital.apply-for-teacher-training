module ProviderInterface
  class InterviewsController < ProviderInterfaceController
    before_action :set_application_choice

    def new
      @interview_form = InterviewForm.new({application_choice: @application_choice, current_provider_user: current_provider_user})
    end

    def check
      @interview_form = InterviewForm.new(interview_params)

      render :new unless @interview_form.valid?
    end

    def create
      @interview_form = InterviewForm(interview_params)
      @interview_form.save
      redirect_to provider_interface_application_choice_path(@application_choice)
    end

  private

    def interview_params
      params
        .require(:provider_interface_interview_form)
        .permit(:'date(3i)', :'date(2i)', :'date(1i)', :time, :location, :additional_details, :provider_id)
        .transform_keys { |key| date_field_to_attribute(key) }
        .transform_values(&:strip)
        .merge(application_choice: @application_choice, current_provider_user: current_provider_user)
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
