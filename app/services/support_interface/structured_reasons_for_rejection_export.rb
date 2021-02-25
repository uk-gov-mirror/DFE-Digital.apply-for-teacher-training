module SupportInterface
  class StructuredReasonsForRejectionExport
    def data_for_export
      data_for_export = application_forms.includes(:application_choices).each do |application_form|
        structured_reasons_for_rejection = FlatReasonsForRejectionExtract.new(application_form.application_choices.rejected&.structured_rejection_reasons)

        output = {
          'Candidate behaviour' => structured_reasons_for_rejection.candidate_behaviour?,
          'Candidate behaviour - didnt_reply_to_interview_offer' => structured_reasons_for_rejection.didnt_reply_to_interview_offer?,
          'Candidate behaviour - didnt_attend_interview' => structured_reasons_for_rejection.didnt_attend_interview?,
          'Candidate behaviour - other detail' => structured_reasons_for_rejection.candidate_behaviour_other_details,

        }

        output
      end

      # The DataExport class creates the header row for us so we need to ensure
      # we sort by longest hash length to ensure all headers appear
      data_for_export.sort_by(&:length).reverse
    end

  private

    def application_forms
      ApplicationForm
        .includes(:application_choices)
        .where.not(equality_and_diversity: nil)
    end
  end
end
