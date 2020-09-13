module CandidateInterface
  class NationalitiesForm
    include ActiveModel::Model

    attr_accessor :first_nationality, :second_nationality, :british, :irish, :other,
                  :other_nationality1, :other_nationality2, :other_nationality3, :nationalities

    validates :first_nationality, presence: true, unless: :international_flag_is_on?

    validates :first_nationality, :second_nationality, :other_nationality1, :other_nationality2, :other_nationality3,
              inclusion: { in: NATIONALITY_DEMONYMS, allow_blank: true }

    validate :candidate_provided_nationality, if: :international_flag_is_on?

    UK_AND_IRISH_NATIONALITIES = ['British', 'Welsh', 'Scottish', 'Northern Irish', 'Irish', 'English'].freeze

    def self.build_from_application(application_form)
      if FeatureFlag.active?('international_personal_details')
        new(
          application_form.build_nationalities_hash,
        )
      else
        new(
          first_nationality: application_form.first_nationality,
          second_nationality: application_form.second_nationality,
        )
      end
    end

    def save(application_form)
      return false unless valid?

      if FeatureFlag.active?('international_personal_details')
        nationalities = candidates_nationalities

        application_form.update!(
          first_nationality: nationalities[0],
          second_nationality: nationalities[1],
          third_nationality: nationalities[2],
          fourth_nationality: nationalities[3],
          fifth_nationality: nationalities[4],
        )
      else
        application_form.update!(
          first_nationality: first_nationality,
          second_nationality: second_nationality,
        )
      end
    end

    def candidates_nationalities
      other.present? ? [british, irish, other_nationality1, other_nationality2, other_nationality3].select(&:present?).uniq : [british, irish].select(&:present?)
    end

  private

    def international_flag_is_on?
      FeatureFlag.active?('international_personal_details')
    end

    def candidate_provided_nationality
      errors.add(:nationalities, :blank) if [british, irish, other].all?(&:blank?)
      if other.present? && other_nationality1.blank?
        # 'nationalities' needs to be set in order for govuk form builder to be able to display this error
        self.nationalities = ['other', british, irish].compact
        errors.add(:other_nationality1, :blank)
      end
    end
  end
end
