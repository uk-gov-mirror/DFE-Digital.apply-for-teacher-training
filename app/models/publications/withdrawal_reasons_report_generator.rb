module Publications
  class WithdrawalReasonsReportGenerator
    attr_reader :client

    def initialize(provider_id:, recruitment_cycle_year: RecruitmentCycleTimetable.current_year)
      @client = DfE::Bigquery::WithdrawalReasonsMetrics.new(
        provider_id:,
        recruitment_cycle_year:,
      )
    end

    def call
      Publications::WithdrawalReasonsReport.create!(
        provider_id:,
        recruitment_cycle_year:,
        statistics: data,
      )
    end

    delegate :data, to: :client
  end
end
