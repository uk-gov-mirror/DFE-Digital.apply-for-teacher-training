module Publications
  class WithdrawalReasonsReportWorker < ApplicationJob
    queue_as :default

    retry_on StandardError, attempts: 3

    def perform
      Provider.find_each.each do |provider|
        Publications::WithdrawalReasonsReportGenerator.new.call(
          provider_id: provider.id,
        )
      end
    end
  end
end
