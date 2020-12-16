module ProviderInterface
  class MakeOfferForm
    include ActiveModel::Model

    STANDARD_CONDITIONS = ['Fitness to Teach check', 'Disclosure and Barring Service (DBS) check'].freeze

    attr_accessor :standard_conditions, :course_option_id, :application_choice
    attr_writer :further_conditions

    validate :validate_further_conditions

    def offer
      Offer.new(
        application_choice: application_choice,
        course_option: course_option,
        conditions: conditions,
      )
    end

    def conditions
      [
        standard_conditions.presence || STANDARD_CONDITIONS,
        further_conditions.map(&:condition_text),
      ].flatten.reject(&:blank?)
    end

    def course_option
      CourseOption.find(course_option_id)
    end

    def further_conditions
      @further_conditions || Array.new(4) { |n| FurtherCondition.new(id: n) }
    end

    def further_conditions_attributes=(attributes)
      @further_conditions = attributes.map { |_id, attrs| FurtherCondition.new(attrs) }
    end

    class FurtherCondition
      include ActiveModel::Model
      attr_accessor :condition_text, :id

      validates :condition_text, length: { maximum: Offer::MAX_CONDITION_LENGTH }
    end

    def standard_conditions_checkboxes
      STANDARD_CONDITIONS.map do |condition|
        OpenStruct.new(
          id: condition,
          name: condition,
        )
      end
    end

  private

    def validate_further_conditions
      @further_conditions.each do |condition|
        condition.valid?
        condition.errors.each do |key, message|
          errors.add("further_conditions_attributes[#{condition.id}][#{key}]", message)
        end
      end
    end
  end
end
