module CandidateInterface
  class CompleteSectionComponent < ViewComponent::Base
    attr_reader :section_complete_form, :path, :request_method, :summary_component

    def initialize(section_complete_form:, path:, request_method:, summary_component:)
      @section_complete_form = section_complete_form
      @path = path
      @request_method = request_method
      @summary_component = summary_component
    end
  end
end
