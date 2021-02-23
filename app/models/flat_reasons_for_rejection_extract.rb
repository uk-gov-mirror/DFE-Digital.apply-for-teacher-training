class FlatReasonsForRejectionExtract
  include ActiveModel::Model

  def initialize(application_choice)
    # @structured_rejection_reasons = application_form.application_choices.structured_rejection_reasons
    @structured_rejection_reasons = application_choice.structured_rejection_reasons
  end

  # def structured_rejection_data(structured_rejection_reasons)
  # end

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