module DfE
  module Bigquery
    class WithdrawalReasonsMetrics
      include ::DfE::Bigquery::Relation

      SELECT_COLUMNS = %w[
        provider_code
        provider_id
        provider_name
        recruitment_cycle_year
        withdrawal_tier
        tier_withdrawal_reason
        before_accepting
        after_accepting
      ].freeze

      attr_reader :provider_id, :recruitment_cycle_year

      def initialize(provider_id: nil, recruitment_cycle_year: nil)
        @provider_id = provider_id&.to_s
        @recruitment_cycle_year = recruitment_cycle_year || (defined?(RecruitmentCycleTimetable) ? RecruitmentCycleTimetable.current_year : nil)
      end

      def table_name
        '1_key_tables.provider_withdrawal_reasons'
      end

      def data
        query(
          select(SELECT_COLUMNS.join(', '))
          .where(
            provider_id:,
            recruitment_cycle_year:,
          ).to_sql,
        )
      end

    private

      def result_class = self.class::Result

      class Result
        ATTRIBUTES = SELECT_COLUMNS.map { |column| column.to_s.tr('.', '_') }
        attr_reader(*ATTRIBUTES)

        def initialize(attributes)
          attributes.each do |key, value|
            key = 'provider_id' if key == :id

            if respond_to?(key)
              instance_variable_set("@#{key}", value)
            end
          end
        end

        def attributes
          attrs = {}
          (ATTRIBUTES + ['nonprovider_filter', 'number_of_candidates_submitted_to_same_date_previous_cycle']).uniq.each do |curr|
            if instance_variable_defined?("@#{curr}")
              attrs[curr.to_s] = instance_variable_get("@#{curr}")
            elsif respond_to?(curr)
              begin
                attrs[curr.to_s] = public_send(curr)
              rescue
                attrs[curr.to_s] = nil
              end
            else
              attrs[curr.to_s] = nil
            end
          end
          attrs
        end
      end
    end
  end
end
