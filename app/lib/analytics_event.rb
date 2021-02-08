class AnalyticsEvent
  CLIENT = SimpleSegment::Client.new(
    write_key: 'ReXI48ZIFSXD82KI1ZTuotyLMu2PHUib',
  )

  def self.emit(name, candidate: nil)

    if candidate
      user_id = "Candidate##{candidate.id}"
    else
      user_id = nil
    end

    analytics.track(
      user_id: user_id,
      event: name,
    )

    event_attributes = {}

    event_attributes.merge!(RequestLocals.fetch(:identity) { } || {})
    event_attributes.merge!(RequestLocals.fetch(:debugging_info) {} || {})
    event_attributes.merge!(RequestLocals.fetch(:params) {} || {})
  end
end
