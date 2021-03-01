class ReasonsForRejection
  include ActiveModel::Model

  INITIAL_TOP_LEVEL_QUESTIONS = %i[
    candidate_behaviour_y_n
    quality_of_application_y_n
    qualifications_y_n
    performance_at_interview_y_n
    course_full_y_n
    offered_on_another_course_y_n
    honesty_and_professionalism_y_n
    safeguarding_y_n
  ].freeze

  ALL_QUESTIONS = {
    candidate_behaviour_y_n: {
      candidate_behaviour_what_did_the_candidate_do: {
        other: %i[candidate_behaviour_other candidate_behaviour_what_to_improve],
      },
    },
    quality_of_application_y_n: {
      quality_of_application_which_parts_needed_improvement: {
        personal_statement: :quality_of_application_personal_statement_what_to_improve,
        subject_knowledge: :quality_of_application_subject_knowledge_what_to_improve,
        other: %i[quality_of_application_other_details quality_of_application_other_what_to_improve],
      },
    },
    qualifications_y_n: {
      qualifications_which_qualifications: {
        other: :qualifications_other_details,
      },
    },
    performance_at_interview_y_n: { performance_at_interview_what_to_improve: nil },
    offered_on_another_course_y_n: { offered_on_another_course_details: nil },
    honesty_and_professionalism_y_n: {
      honesty_and_professionalism_concerns: {
        information_false_or_inaccurate: :honesty_and_professionalism_concerns_information_false_or_inaccurate_details,
        plagiarism: :honesty_and_professionalism_concerns_plagiarism_details,
        references: :honesty_and_professionalism_concerns_references_details,
        other: :honesty_and_professionalism_concerns_other_details,
      },
    },
    safeguarding_y_n: {
      safeguarding_concerns: {
        candidate_disclosed_information: :safeguarding_concerns_candidate_disclosed_information_details,
        vetting_disclosed_information: :safeguarding_concerns_vetting_disclosed_information_details,
        other: :safeguarding_concerns_other_details,
      },
    },
    other_advice_or_feedback_y_n: { other_advice_or_feedback_details: nil },
  }.freeze
  INITIAL_QUESTIONS = ALL_QUESTIONS.select { |key| INITIAL_TOP_LEVEL_QUESTIONS.include?(key) }.freeze

  attr_accessor :candidate_behaviour_y_n
  attr_writer :candidate_behaviour_what_did_the_candidate_do
  attr_accessor :candidate_behaviour_what_to_improve
  attr_accessor :candidate_behaviour_other

  def candidate_behaviour_what_did_the_candidate_do
    @candidate_behaviour_what_did_the_candidate_do || []
  end

  attr_accessor :quality_of_application_y_n
  attr_writer :quality_of_application_which_parts_needed_improvement
  attr_accessor :quality_of_application_personal_statement_what_to_improve
  attr_accessor :quality_of_application_subject_knowledge_what_to_improve
  attr_accessor :quality_of_application_other_details
  attr_accessor :quality_of_application_other_what_to_improve

  def quality_of_application_which_parts_needed_improvement
    @quality_of_application_which_parts_needed_improvement || []
  end

  attr_accessor :qualifications_y_n
  attr_writer :qualifications_which_qualifications
  attr_accessor :qualifications_other_details

  def qualifications_which_qualifications
    @qualifications_which_qualifications || []
  end

  attr_accessor :performance_at_interview_y_n
  attr_accessor :performance_at_interview_what_to_improve

  attr_accessor :course_full_y_n

  attr_accessor :offered_on_another_course_y_n
  attr_accessor :offered_on_another_course_details

  attr_accessor :honesty_and_professionalism_y_n
  attr_writer :honesty_and_professionalism_concerns
  attr_accessor :honesty_and_professionalism_concerns_information_false_or_inaccurate_details
  attr_accessor :honesty_and_professionalism_concerns_plagiarism_details
  attr_accessor :honesty_and_professionalism_concerns_references_details
  attr_accessor :honesty_and_professionalism_concerns_other_details

  def honesty_and_professionalism_concerns
    @honesty_and_professionalism_concerns || []
  end

  attr_accessor :safeguarding_y_n
  attr_writer :safeguarding_concerns
  attr_accessor :safeguarding_concerns_candidate_disclosed_information_details
  attr_accessor :safeguarding_concerns_vetting_disclosed_information_details
  attr_accessor :safeguarding_concerns_other_details

  def safeguarding_concerns
    @safeguarding_concerns || []
  end

  attr_accessor :other_advice_or_feedback_y_n
  attr_accessor :other_advice_or_feedback_details

  attr_accessor :interested_in_future_applications_y_n

  attr_accessor :why_are_you_rejecting_this_application

  def to_prose
    safeguarding_y_n.to_s
  end

  INITIAL_TOP_LEVEL_QUESTIONS.each do |reason|
    define_method(reason.to_s.gsub(/_y_n$/, '?')) do
      self.send(reason) == 'Yes'
    end

    define_method(reason.to_s.gsub(/_y_n$/, '?=')) do |value|
      self.send(
        "#{reason}=",
        value ? 'Yes' : 'No',
      )
    end
  end

  ALL_QUESTIONS.each do |reason, sub_reasons|
    sub_reasons.each do |sub_reason|
      ReasonsForRejectionCountQuery::TOP_LEVEL_REASONS_TO_SUB_REASONS.each do |reason, sub_reason|
        ReasonsForRejectionCountQuery::SUBREASON_VALUES[reason.to_sym].each do |sub_reason_value|
          define_method("#{reason.to_s.gsub(/_y_n$/, '')}_#{sub_reason_value}?") do
            self.send(sub_reason).include?(sub_reason_value.to_s)
          end

          define_method("#{reason.to_s.gsub(/_y_n$/, '')}_#{sub_reason_value}?=") do |value|
            values = self.send(sub_reason)
            if value
              return if values.include?(sub_reason_value)

              self.send("#{sub_reason}=", values << sub_reason_value)
            else
              self.send("#{sub_reason}=", values.except(sub_reason_value))
            end
          end
        end
      end
    end
  end
end
