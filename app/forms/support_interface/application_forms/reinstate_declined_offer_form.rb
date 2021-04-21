module SupportInterface
  module ApplicationForms
    class ReinstateDeclinedOfferForm
      include ActiveModel::Model

      attr_accessor :accept_guidance, :status, :audit_comment

      validates :accept_guidance, presence: true
      validates :status, presence: true
      validates :audit_comment, presence: true

      def self.build_from_course_choice(course_choice)
        new(
          status: ApplicationChoice.where(id: course_choice).first.status
        )
      end

      def save(course_choice)
        return false unless valid?

        course_choice.update!(
          status: 'Offer made',
          declined_at: nil,
          declined_by_default: false,
          decline_by_default_at: 10.days.from_now,
          audit_comment: "Reinstate offer Zendesk request: #{audit_comment_ticket}",
        )
      end
    end
  end
end
