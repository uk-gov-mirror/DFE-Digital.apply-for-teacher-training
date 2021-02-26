module SupportInterface
  class StructuredReasonsForRejectionExport
    def data_for_export
      data_for_export = application_choices.map do |application_choice|
        structured_reasons_for_rejection = FlatReasonsForRejectionExtract.new(application_choice.structured_rejection_reasons)

        output = {
          'Candidate ID' => application_choice.id,
          'Candidate behaviour' => structured_reasons_for_rejection.candidate_behaviour?,
          'Candidate behaviour - Didn’t reply to our interview offer' => structured_reasons_for_rejection.didnt_reply_to_interview_offer?,
          'Candidate behaviour - Didn’t attend an interview' => structured_reasons_for_rejection.didnt_attend_interview?,
          'Candidate behaviour - Other detail' => structured_reasons_for_rejection.candidate_behaviour_other_details,
          'Quality of application' => structured_reasons_for_rejection.quality_of_application?,
          'Quality of application - personal statement' => structured_reasons_for_rejection.personal_statement?,
          'Quality of application - personal statement details' => structured_reasons_for_rejection.quality_of_application_personal_statement_what_to_improve,
          'Quality of application - subject knowledge' => structured_reasons_for_rejection.subject_knowledge?,
          'Quality of application - subject knowledge details' => structured_reasons_for_rejection.quality_of_application_subject_knowledge_what_to_improve,
          'Quality of application - other details' => structured_reasons_for_rejection.quality_of_application_other_details,
          'Qualifications' => structured_reasons_for_rejection.qualifications?,
          'Qualifications - no maths gcse or equivalent' => structured_reasons_for_rejection.no_maths_gcse?,
          'Qualifications - no science gcse or equivalent' => structured_reasons_for_rejection.no_science_gcse?,
          'Qualifications - no english gcse or equivalent' => structured_reasons_for_rejection.no_english_gcse?,
          'Qualifications - no degree' => structured_reasons_for_rejection.no_degree?,
          'Qualifications - other detail' => structured_reasons_for_rejection.qualifications_other_details,
          'Performance at interview' => structured_reasons_for_rejection.performance_at_interview?,
          'Performance at interview - What to improve' => structured_reasons_for_rejection.performance_at_interview_what_to_improve,
          'Course was full?' => structured_reasons_for_rejection.course_full?,
          'Offered another course' => structured_reasons_for_rejection.offered_on_another_course?,
          'Concerns about honesty and professionalism' => structured_reasons_for_rejection.honesty_and_professionalism?,
          'Honesty and professionalism - False or inaccurate information' => structured_reasons_for_rejection.information_false_or_inaccurate?,
          'Honesty and professionalism - Information given on application form false or inaccurate' => structured_reasons_for_rejection.honesty_and_professionalism_concerns_information_false_or_inaccurate_details,
          'Honesty and professionalism - Plagiarism' => structured_reasons_for_rejection.plagiarism?,
          'Honesty and professionalism - Evidence of plagiarism in personal statement or elsewhere' => structured_reasons_for_rejection.honesty_and_professionalism_concerns_plagiarism_details,
          'Honesty and professionalism - References' => structured_reasons_for_rejection.references?,
          'Honesty and professionalism - References didn’t support application' => structured_reasons_for_rejection.honesty_and_professionalism_concerns_references_details,
          'Honesty and professionalism - Other Concerns about honesty and professionalism' => structured_reasons_for_rejection.honesty_and_professionalism_concerns_other_details,
          'Safeguarding' => 'hi',
          'Information disclosed by candidate makes them unsuitable to work with children' => 'hi',
          'Information revealed by our vetting process makes the candidate unsuitable to work with children' => 'hi',
          'Safeguarding other' => 'hi',
        }

        output
      end


      # The DataExport class creates the header row for us so we need to ensure
      # we sort by longest hash length to ensure all headers appear
      # data_for_export.sort_by(&:length).reverse
      data_for_export.sort_by { |application| application["Candidate ID"] }
    end

  private

    def application_choices
      ApplicationChoice.where.not(structured_rejection_reasons: nil)
    end
  end
end
