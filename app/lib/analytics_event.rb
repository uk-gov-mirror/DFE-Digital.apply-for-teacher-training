class AnalyticsEvent
  CLIENT = SimpleSegment::Client.new(
    write_key: 'ReXI48ZIFSXD82KI1ZTuotyLMu2PHUib',
  )

  def self.identify(candidate:)
    CLIENT.identify(
      user_id: "Candidate##{candidate.id}",
      traits: {
        email: candidate.email_address,
      }
    )
  end

  def self.emit(name, candidate: nil, session:)
    return unless FeatureFlag.active?(:event_tracking)

    event_params = {
      event: name,
    }

    if candidate
      event_params.merge!(user_id: "Candidate##{candidate.id}")
    else
      event_params.merge!(anonymous_id: session[:session_id])
    end

    CLIENT.track(event_params)
  end
end
