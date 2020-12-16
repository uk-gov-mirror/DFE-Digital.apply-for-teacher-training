module ProviderInterface
  class DecisionsController < ProviderInterfaceController
    before_action :set_application_choice
    before_action :requires_make_decisions_permission
    before_action :redirect_to_structured_reasons_for_rejection_if_enabled, only: %i[new_reject confirm_reject create_reject]

    def respond
      @pick_response_form = PickResponseForm.new
      @alternative_study_mode = @application_choice.offered_option.alternative_study_mode
    end

    def submit_response
      @pick_response_form = PickResponseForm.new(decision: params.dig(:provider_interface_pick_response_form, :decision))
      if @pick_response_form.valid?
        redirect_to @pick_response_form.redirect_attrs
      else
        render action: :respond
      end
    end

    def new_offer
      course_option = if params[:course_option_id]
                        CourseOption.find(params[:course_option_id])
                      else
                        @application_choice.course_option
                      end

      @make_offer_form = ProviderInterface::MakeOfferForm.new(course_option_id: course_option.id)
    end

    def confirm_offer
      @make_offer_form = ProviderInterface::MakeOfferForm.new(make_offer_form_params.merge(application_choice: @application_choice))

      if !@make_offer_form.valid?
        render action: :new_offer
      end
    end

    def create_offer
      @make_offer_form = ProviderInterface::MakeOfferForm.new(make_offer_form_params.merge(application_choice: @application_choice))

      if !@make_offer_form.valid?
        render action: :new_offer
      end

      make_offer = MakeAnOffer.new(
        actor: current_provider_user,
        offer: @make_offer_form.offer,
      )

      if make_offer.save
        flash[:success] = 'Offer successfully made to candidate'
        redirect_to provider_interface_application_choice_path(
          application_choice_id: @application_choice.id,
        )
      else
        render action: :new_offer
      end
    end

    def new_reject
      @reject_application = RejectApplication.new(
        actor: current_provider_user,
        application_choice: @application_choice,
      )
    end

    def confirm_reject
      @reject_application = RejectApplication.new(
        actor: current_provider_user,
        application_choice: @application_choice,
        rejection_reason: params.dig(:reject_application, :rejection_reason),
      )
      render action: :new_reject if !@reject_application.valid?
    end

    def create_reject
      @reject_application = RejectApplication.new(
        actor: current_provider_user,
        application_choice: @application_choice,
        rejection_reason: params.dig(:reject_application, :rejection_reason),
      )
      if @reject_application.save
        flash[:success] = 'Application successfully rejected'
        redirect_to provider_interface_application_choice_path(
          application_choice_id: @application_choice.id,
        )
      else
        render action: :new_reject
      end
    end

    def new_withdraw_offer
      @withdraw_offer = WithdrawOffer.new(
        actor: current_provider_user,
        application_choice: @application_choice,
      )
    end

    def confirm_withdraw_offer
      @withdraw_offer = WithdrawOffer.new(
        actor: current_provider_user,
        application_choice: @application_choice,
        offer_withdrawal_reason: params.dig(:withdraw_offer, :offer_withdrawal_reason),
      )
      if !@withdraw_offer.valid?
        render action: :new_withdraw_offer
      end
    end

    def withdraw_offer
      @withdraw_offer = WithdrawOffer.new(
        actor: current_provider_user,
        application_choice: @application_choice,
        offer_withdrawal_reason: params.dig(:withdraw_offer, :offer_withdrawal_reason),
      )
      if @withdraw_offer.save
        flash[:success] = 'Offer successfully withdrawn'
        redirect_to provider_interface_application_choice_path(
          application_choice_id: @application_choice.id,
        )
      else
        render action: :new_withdraw_offer
      end
    end

    def new_defer_offer
      @defer_offer = DeferOffer.new(
        actor: current_provider_user,
        application_choice: @application_choice,
      )
    end

    def defer_offer
      DeferOffer.new(
        actor: current_provider_user,
        application_choice: @application_choice,
      ).save!

      flash[:success] = 'Offer successfully deferred'
      redirect_to provider_interface_application_choice_path(@application_choice)
    end

  private

    def make_offer_form_params
      params.require(:provider_interface_make_offer_form).permit(:course_option_id, standard_conditions: [], further_conditions_attributes: {})
    end

    def redirect_to_structured_reasons_for_rejection_if_enabled
      if FeatureFlag.active?(:structured_reasons_for_rejection)
        redirect_to provider_interface_reasons_for_rejection_initial_questions_path(@application_choice)
      end
    end
  end
end
