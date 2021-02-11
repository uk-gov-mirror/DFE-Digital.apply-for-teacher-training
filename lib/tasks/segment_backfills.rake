namespace :segment do
  task identify_candidates: [:environment] do
    Candidate.find_each do |candidate|
      AnalyticsEvent.identify(candidate: candidate)
    end
  end

  task backfill_updates: [:environment] do
    Audited::Audit.where(auditable_type: "ApplicationForm", user_type: "Candidate").each do |a|
      AnalyticsEvent::CLIENT.track(
        event: "Update application form",
        user_id: "Candidate##{a.user_id}",
        properties: a.audited_changes,
      )
    end
  end
end
