module ProviderInterface
  class FeedbackController < ProviderInterfaceController
    before_action :set_application_choice
    before_action :requires_make_decisions_permission
    before_action :requires_rbd_application_with_no_feedback

    def new
      # feedback_params used in case you arrive here via the Change link
      @application_feedback = RejectedByDefaultFeedbackForm.new(feedback_params)
    end

    def check
      @application_feedback = RejectedByDefaultFeedbackForm.new(feedback_params)
      @application_feedback.valid? || render(action: :new)
    end

    def create
      SaveAndSendRejectByDefaultFeedback.new(
        application_choice: @application_choice,
        rejection_reason: feedback_params[:rejection_reason],
      ).call!

      flash[:success] = 'Feedback sent'

      redirect_to provider_interface_application_choice_path(
        application_choice_id: @application_choice.id,
      )
    end

  private

    def requires_rbd_application_with_no_feedback
      return if @application_choice.status == 'rejected' &&
        @application_choice.rejected_by_default &&
        @application_choice.rejection_reason.blank?

      redirect_to provider_interface_application_choice_path(
        application_choice_id: @application_choice.id,
      ) and return
    end

    def feedback_params
      return {} unless params.key?(:provider_interface_rejected_by_default_feedback_form)

      params.require(:provider_interface_rejected_by_default_feedback_form)
        .permit(:rejection_reason)
    end
  end
end
