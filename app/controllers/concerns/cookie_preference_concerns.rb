module CookiePreferenceConcerns
  def create
    @cookie_preferences = CookiePreferencesForm.new(consent: cookie_preferences_consent)
    cookies[consent_cookie] = { value: @cookie_preferences.consent, expires: 6.months.from_now }
    flash[:success] = 'Your cookie preferences have been updated'

    redirect_back(fallback_location: cookie_page_path)
  end

private

  def cookie_preferences_consent
    cookie_preference_params = params.key?(:cookie_preferences_form) ? params[:cookie_preferences_form] : params
    cookie_preference_params.permit(:consent)[:consent]
  end
end
