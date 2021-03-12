module CandidateInterface
  class PersonalDetailsForm
    include ActiveModel::Model
    include DateField

    attr_accessor :first_name, :last_name
    date_field :date_of_birth

    validates :first_name, :last_name, presence: true, length: { maximum: 60 }
    validates :date_of_birth, date: { date_of_birth: true, presence: true }

    def self.build_from_application(application_form)
      new(
        first_name: application_form.first_name,
        last_name: application_form.last_name,
        date_of_birth: application_form.date_of_birth
      )
    end

    def save(application_form)
      return false unless valid?

      application_form.update(
        first_name: first_name,
        last_name: last_name,
        date_of_birth: date_of_birth,
      )
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end
