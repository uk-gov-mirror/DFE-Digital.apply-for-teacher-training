class FlatReasonsForRejectionExtract
  include ActiveModel::Model

  def initialize(structured_rejection_reasons)
    @structured_rejection_reasons = structured_rejection_reasons
  end

  def top_level_reasons
    I18n.t('reasons_for_rejection_copy.top_level_reasons').keys
  end

  def top_level_reason_title(reason)
    I18n.t("reasons_for_rejection_copy.top_level_reasons.#{reason}.title")
  end

  def separate_high_level_rejection_reasons(structured_rejection_reasons)
    select_high_level_rejection_reasons(structured_rejection_reasons)
    .keys
    .map { |reason| format_reason(reason) }
  end

  def candidate_behaviour
    return nil if @structured_rejection_reasons.blank?
    @structured_rejection_reasons.select { |reason, value| value == 'candidate_behaviour_y_n' }

    select_high_level_rejection_reasons(structured_rejection_reasons)
    .keys
    .map { |reason| format_reason(reason) }
  end

  def qualifications

  end

  def quality_of_application


  end

  def quality_of_application_sub_reasons


  end

  def candidate_behaviour?
    return nil if @structured_rejection_reasons['candidate_behaviour_y_n'].blank?

    @structured_rejection_reasons.select { |reason, value| value == 'Yes' && reason == 'candidate_behaviour_y_n' }.present?
  end

  def didnt_reply_to_interview_offer?
    return nil if @structured_rejection_reasons['candidate_behaviour_what_did_the_candidate_do'].blank?

    @structured_rejection_reasons['candidate_behaviour_what_did_the_candidate_do'].include?("didnt_reply_to_interview_offer")
  end

  def didnt_attend_interview?
    return nil if @structured_rejection_reasons['candidate_behaviour_what_did_the_candidate_do'].blank?

    @structured_rejection_reasons['candidate_behaviour_what_did_the_candidate_do'].include?("didnt_attend_interview")
  end

  def candidate_behaviour_other_details
    return nil if @structured_rejection_reasons['candidate_behaviour_other'].blank?

    @structured_rejection_reasons['candidate_behaviour_other']
  end


  # These three methods are copied from the application_choices_export.rb .... currently doesn't provide enough granularity
  def format_structured_rejection_reasons
    return nil if @structured_rejection_reasons.blank?

    select_high_level_rejection_reasons(@structured_rejection_reasons)
    .keys
    .map { |reason| format_reason(reason) }
    .join("\n")
  end

  def select_high_level_rejection_reasons(structured_rejection_reasons)
    structured_rejection_reasons.select { |reason, value| value == 'Yes' && reason.include?('_y_n') }
  end

  def format_reason(reason)
    reason
    .delete_suffix('_y_n')
    .humanize
  end
end
