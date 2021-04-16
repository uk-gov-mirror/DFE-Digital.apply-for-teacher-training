module CandidateInterface
  class ProviderFeedback
    class UnsupportedSectionError < StandardError; end

    class << self
      def from_previous_applications(application_form, section)
        reasons_for_rejection_method = map_section_to_method(section)
        previous_applications = collect_previous_applications(application_form)
        return [] if previous_applications.blank?

        previous_applications.flat_map do |application|
          application.application_choices.map do |choice|
            reasons_for_rejection = ReasonsForRejection.new choice.structured_rejection_reasons
            feedback = reasons_for_rejection.send reasons_for_rejection_method
            new(
              choice.provider.name,
              section,
              feedback,
            )
          end
        end
      end

      def collect_previous_applications(application_form)
        previous = application_form.previous_application_form
        [].tap do |collection|
          while previous.present?
            collection << previous
            previous = previous.previous_application_form
          end
        end
      end

      def map_section_to_method(section)
        case section
        when :becoming_a_teacher
          :quality_of_application_personal_statement_what_to_improve
        else
          raise UnsupportedSectionError
        end
      end
    end

    attr_reader :provider_name, :section, :feedback

    def initialize(provider_name, section, feedback)
      @provider_name = provider_name
      @section = section
      @feedback = feedback
    end

    def ==(other)
      provider_name == other.provider_name &&
        section == other.section &&
        feedback == other.feedback
    end
  end
end
