module SupportInterface
  module ApplicationForms
    class ApplicationChoicesController < SupportInterfaceController
      def reinstate_offer
        @declined_course_choice = ReinstateDeclinedOfferForm.build_from_course_choice(params[:application_choice_id])
      end

      def confirm_reinstate_offer
        @declined_course_choice = ReinstateDeclinedOfferForm.new(params[:application_choice_id])

        if @declined_course_choice.save(params[:application_choice_id])
          flash[:success] = 'Offer was reinstated'
          redirect_to support_interface_application_form_path(params[:application_form_id])
        else
          # track_validation_error(@declined_course_choice)
          render :reinstate_offer
        end
      end
    end
  end
end
