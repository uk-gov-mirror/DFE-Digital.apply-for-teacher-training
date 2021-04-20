module ProviderInterface
  class OfferWizard
    include ActiveModel::Model

    STEPS = { make_offer: %i[select_option conditions check],
              change_offer: %i[select_option providers courses study_modes locations conditions check] }.freeze
    NUMBER_OF_FURTHER_CONDITIONS = 4

    attr_accessor :provider_id, :course_id, :course_option_id, :study_mode, :location_id,
                  :standard_conditions, :further_conditions, :current_step, :decision,
                  :action, :path_history, :wizard_path_history,
                  :provider_user_id, :application_choice_id

    validates :decision, presence: true, on: %i[select_option]
    validates :course_option_id, presence: true, on: %i[locations save]
    validates :study_mode, presence: true, on: %i[study_modes save]
    validates :course_id, presence: true, on: %i[courses save]
    validate :further_conditions_valid, on: %i[conditions]
    validate :course_option_details, if: :course_option_id, on: :save

    def initialize(state_store, attrs = {})
      @state_store = state_store

      super(last_saved_state.deep_merge(attrs))
      setup_further_conditions
      update_path_history(attrs)
    end

    def self.build_from_application_choice(state_store, application_choice, options = {})
      course_option = application_choice.current_course_option

      attrs = {
        application_choice_id: application_choice.id,
        course_id: course_option.course.id,
        course_option_id: course_option.id,
        provider_id: course_option.provider.id,
        study_mode: course_option.study_mode,
        location_id: course_option.site.id,
        decision: :default,
        standard_conditions: standard_conditions_from(application_choice.offer),
        further_conditions: further_conditions_from(application_choice.offer),
      }.merge(options)

      new(state_store, attrs)
    end

    def conditions
      @conditions = (standard_conditions + further_conditions).reject(&:blank?)
    end

    def course_option
      CourseOption.find(course_option_id)
    end

    def save_state!
      @state_store.write(state)
    end

    def clear_state!
      @state_store.delete
    end

    def valid_for_current_step?
      valid?(current_step.to_sym)
    end

    def next_step(step = current_step)
      index = STEPS[decision.to_sym].index(step.to_sym)
      return unless index

      next_step = STEPS[decision.to_sym][index + 1]

      return save_and_go_to_next_step(next_step) if next_step.eql?(:providers) && available_providers.length == 1
      return save_and_go_to_next_step(next_step) if next_step.eql?(:courses) && available_courses.length == 1
      return save_and_go_to_next_step(next_step) if next_step.eql?(:study_modes) && available_study_modes.length == 1
      return save_and_go_to_next_step(next_step) if next_step.eql?(:locations) && available_course_options.length == 1

      next_step
    end

    delegate :previous_step, to: :wizard_path_history

    def condition_models
      @_condition_models ||= further_conditions.map.with_index do |further_condition, index|
        OfferConditionField.new(id: index, text: further_condition)
      end
    end

  private

    def self.standard_conditions_from(offer)
      return MakeAnOffer::STANDARD_CONDITIONS if offer.blank?

      conditions = offer['conditions']
      conditions & MakeAnOffer::STANDARD_CONDITIONS
    end

    private_class_method :standard_conditions_from

    def self.further_conditions_from(offer)
      return [] if offer.blank?

      conditions = offer['conditions']
      conditions - MakeAnOffer::STANDARD_CONDITIONS
    end

    private_class_method :further_conditions_from

    def course_option_details
      OfferedCourseOptionDetailsCheck.new(provider_id: provider_id,
                                          course_id: course_id,
                                          course_option_id: course_option_id,
                                          study_mode: study_mode).validate!
    rescue OfferedCourseOptionDetailsCheck::InvalidStateError => e
      errors.add(:base, e.message)
    end

    def save_and_go_to_next_step(step)
      attrs = { provider_id: available_providers.first.id } if step.eql?(:providers)
      attrs = { course_id: available_courses.first.id } if step.eql?(:courses)
      attrs = { study_mode: available_study_modes.first } if step.eql?(:study_modes)
      attrs = { course_option_id: available_course_options.first.id } if step.eql?(:locations)

      assign_attributes(last_saved_state.deep_merge(attrs))
      save_state!

      next_step(step)
    end

    def query_service
      @query_service ||= GetChangeOfferOptions.new(
        user: provider_user,
        current_course: application_choice.current_course,
      )
    end

    def provider
      Provider.find(provider_id)
    end

    def course
      Course.find(course_id)
    end

    def provider_user
      ProviderUser.find(provider_user_id)
    end

    def application_choice
      ApplicationChoice.find(application_choice_id)
    end

    def available_providers
      query_service.available_providers
    end

    def available_courses
      query_service.available_courses(provider: provider)
    end

    def available_study_modes
      query_service.available_study_modes(course: course)
    end

    def available_course_options
      query_service.available_course_options(course: course, study_mode: study_mode)
    end

    def last_saved_state
      saved_state = @state_store.read
      saved_state ? JSON.parse(saved_state) : {}
    end

    def state
      as_json(
        except: %w[state_store errors validation_context query_service wizard_path_history _condition_models],
      ).to_json
    end

    def update_path_history(attrs)
      @wizard_path_history = WizardPathHistory.new(path_history,
                                                   step: attrs[:current_step].presence,
                                                   action: attrs[:action].presence)
      @wizard_path_history.update
      @path_history = @wizard_path_history.path_history
    end

    def setup_further_conditions
      self.further_conditions = NUMBER_OF_FURTHER_CONDITIONS.times.map do |index|
        existing_value = further_conditions && further_conditions[index]
        existing_value.presence || ''
      end
    end

    def further_conditions_valid
      condition_models.map(&:valid?).all?

      condition_models.each do |model|
        model.errors.each do |error|
          errors.add("further_conditions[#{model.id}][#{error.attribute}]", error.message)
        end
      end
    end
  end
end
