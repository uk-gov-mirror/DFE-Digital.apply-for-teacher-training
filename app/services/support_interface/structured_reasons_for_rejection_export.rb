module SupportInterface
  class StructuredReasonsForRejectionExport
    def data_for_export
      data_for_export = application_choices.map do |application_choice|
        structured_reasons_for_rejection = FlatReasonsForRejectionExtract.new(application_choice.structured_rejection_reasons)

        output = {
          'Candidate behaviour' => structured_reasons_for_rejection.candidate_behaviour?,
          'Candidate behaviour - didnt_reply_to_interview_offer' => structured_reasons_for_rejection.didnt_reply_to_interview_offer?,
          'Candidate behaviour - didnt_attend_interview' => structured_reasons_for_rejection.didnt_attend_interview?,
          'Candidate behaviour - other detail' => structured_reasons_for_rejection.candidate_behaviour_other_details,
          'Quality of application' => structured_reasons_for_rejection.quality_of_application?,
          'Quality of application - personal statement' => structured_reasons_for_rejection.personal_statement?,
          'Quality of application - personal statement details' => structured_reasons_for_rejection.quality_of_application_personal_statement_what_to_improve,
          'Quality of application - subject knowledge' => structured_reasons_for_rejection.subject_knowledge?,
          'Quality of application - subject knowledge details' => structured_reasons_for_rejection.quality_of_application_subject_knowledge_what_to_improve,
          'Quality of application - other details' => structured_reasons_for_rejection.quality_of_application_other_details,
          'Qualifications' => structured_reasons_for_rejection.qualifications?,
          'Qualifications - no maths gcse' => structured_reasons_for_rejection.no_maths_gcse?,
          'Qualifications - no science gcse' => structured_reasons_for_rejection.no_science_gcse?,
          'Qualifications - no english gcse' => structured_reasons_for_rejection.no_english_gcse?,
          'Qualifications - no degree' => structured_reasons_for_rejection.no_degree?,
          'Qualifications - other detail' => structured_reasons_for_rejection.qualifications_other_details,
        }

        output
      end

      # The DataExport class creates the header row for us so we need to ensure
      # we sort by longest hash length to ensure all headers appear
      data_for_export.sort_by(&:length).reverse
    end

  private

    def application_choices
      ApplicationChoice.where.not(structured_rejection_reasons: nil)
    end
  end
end
