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
        provider_code: data[:provider_code],
        provider_name: data[:provider_name],
        withdrawal_tier: data[:withdrawal_tier],
        tier_withdrawal_reason: data[:tier_withdrawal_reason],
        before_accepting: data[:before_accepting],
        after_accepting: data[:after_accepting],
      )
    end
    delegate :data, to: :client
  end
end
