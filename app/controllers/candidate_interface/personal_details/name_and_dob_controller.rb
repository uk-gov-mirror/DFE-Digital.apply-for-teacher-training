module CandidateInterface
  module PersonalDetails
    class NameAndDobController < CandidateInterfaceController
      before_action :redirect_to_dashboard_if_submitted

      def new
        @personal_details_form = PersonalDetailsForm.build_from_application(current_application)
      end

      def create
        @application_form = current_application
        @personal_details_form = PersonalDetailsForm.new(personal_details_params)

        if @personal_details_form.save(current_application)
          current_application.update!(personal_details_completed: false)

          redirect_to candidate_interface_nationalities_path
        else
          track_validation_error(@personal_details_form)
          render :new
        end
      end

      def edit
        @personal_details_form = PersonalDetailsForm.build_from_application(current_application)
      end

      def update
        @application_form = current_application
        @personal_details_form = PersonalDetailsForm.new(personal_details_params)

        if @personal_details_form.save(current_application)
          current_application.update!(personal_details_completed: false)

          redirect_to candidate_interface_personal_details_show_path
        else
          track_validation_error(@personal_details_form)
          render :edit
        end
      end

    private

      def personal_details_params
        strip_whitespace(
          params.require(:candidate_interface_personal_details_form).permit(
            :first_name, :last_name, :date_of_birth))
      end
    end
  end
end
