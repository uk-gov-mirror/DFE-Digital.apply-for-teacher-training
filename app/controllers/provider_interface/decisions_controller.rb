module ProviderInterface
  class DecisionsController < ProviderInterfaceController
    before_action :set_application_choice
    before_action :confirm_application_is_in_decision_pending_state, only: %i[new create]
    before_action :requires_make_decisions_permission

    def new
      @wizard = OfferWizard.new(offer_store,
                                offer_context_params(@application_choice.course_option).merge!(current_step: 'select_option', action: action))
      @wizard.save_state!
    end

    def create
      @wizard = OfferWizard.new(offer_store, { decision: selected_decision })

      if @wizard.valid_for_current_step?

        @wizard.save_state!

        if @wizard.decision == 'rejection'
          redirect_to provider_interface_reasons_for_rejection_initial_questions_path(@application_choice)
        else
          redirect_to [:new, :provider_interface, @application_choice, :offer, @wizard.next_step]
        end
      else
        render 'new'
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
        redirect_to provider_interface_application_choice_feedback_path(
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
      redirect_to provider_interface_application_choice_offer_path(@application_choice)
    end

  private

    def offer_context_params(course_option)
      {
        provider_user_id: current_provider_user.id,
        course_id: course_option.course.id,
        course_option_id: course_option.id,
        provider_id: course_option.provider.id,
        study_mode: course_option.study_mode,
        location_id: course_option.site.id,
        decision: :default,
        standard_conditions: MakeAnOffer::STANDARD_CONDITIONS,
      }
    end

    def confirm_application_is_in_decision_pending_state
      return if ApplicationStateChange::DECISION_PENDING_STATUSES.include?(@application_choice.status.to_sym)

      redirect_to(provider_interface_application_choice_path(@application_choice))
    end

    def provider_interface_offer_params
      params[:provider_interface_offer_wizard] || ActionController::Parameters.new
    end

    def selected_decision
      provider_interface_offer_params.permit(:decision)[:decision]
    end

    def offer_store
      key = "offer_wizard_store_#{current_provider_user.id}_#{@application_choice.id}"
      WizardStateStores::RedisStore.new(key: key)
    end

    def action
      'back' if !!params[:back]
    end
  end
end
