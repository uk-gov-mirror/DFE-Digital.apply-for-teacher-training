require 'rails_helper'

RSpec.describe ProviderInterface::ActivityLogEventComponent do
  def component_for(audit)
    described_class.new(activity_log_event: ActivityLogEvent.new(audit: audit))
  end

  def with_audit(trait)
    audit = create(:application_choice_audit, trait)
    user = audit.user.display_name
    candidate = audit.auditable.application_form.full_name
    yield audit, user, candidate
  end

  describe '#event_description' do
    examples = {
      awaiting_provider_decision: '<candidate> submitted an application',
      withdrawn: '<candidate> withdrew their application',
      with_rejection: '<user> rejected <candidate>’s application',
      with_rejection_by_default: '<candidate>’s application was automatically rejected',
      with_rejection_by_default_and_feedback: '<user> sent feedback to <candidate>',
      with_offer: '<user> made an offer to <candidate>',
      with_modified_offer: '<user> made an offer to <candidate>',
      with_accepted_offer: '<candidate> accepted an offer',
      with_declined_offer: '<candidate> declined an offer',
      with_declined_by_default_offer: '<candidate>’s offer was automatically declined',
      with_withdrawn_offer: '<user> withdrew <candidate>’s offer',
      with_recruited: '<candidate> met all offer conditions',
      with_deferred_offer: '<user> deferred <candidate>’s offer',
    }

    examples.each do |trait, template|
      it "for application #{trait}" do
        with_audit(trait) do |audit, user, candidate|
          expected = template.gsub('<user>', user).gsub('<candidate>', candidate)
          expect(component_for(audit).event_description).to eq(expected)
        end
      end
    end
  end

  describe '#link' do
    let(:routes) { Rails.application.routes.url_helpers }

    it 'shows a link to View application in most cases' do
      with_audit(:awaiting_provider_decision) do |audit, _user, _candidate|
        expect(component_for(audit).link).to eq({
          url: routes.provider_interface_application_choice_path(audit.auditable),
          text: 'View application',
        })
      end
    end

    it 'links to View offer if application is at offer stage' do
      with_audit(:with_offer) do |audit, _user, _candidate|
        expect(component_for(audit).link).to eq({
          url: routes.provider_interface_application_choice_offer_path(audit.auditable),
          text: 'View offer',
        })
      end
    end

    it 'links to View conditions if application is at pending_conditions stage' do
      with_audit(:with_accepted_offer) do |audit, _user, _candidate|
        expect(component_for(audit).link).to eq({
          url: routes.provider_interface_application_choice_offer_path(audit.auditable),
          text: 'View offer',
        })
      end
    end

    it 'says View feedback if showing a feedback event' do
      with_audit(:with_rejection_by_default_and_feedback) do |audit, _user, _candidate|
        expect(component_for(audit).link).to eq({
          url: routes.provider_interface_application_choice_path(audit.auditable),
          text: 'View feedback',
        })
      end
    end
  end

  describe '#course_option' do
    context 'shows the original course option until the offer can be changed' do
      examples = %i[
        awaiting_provider_decision
        with_rejection
        with_rejection_by_default
        with_rejection_by_default_and_feedback
      ]

      examples.each do |trait|
        it "for application #{trait}" do
          with_audit(trait) do |audit, _user, _candidate|
            choice = audit.auditable
            choice.update_columns(offered_course_option_id: create(:course_option).id)
            expect(component_for(audit).course_option.id).to eq(choice.course_option.id)
          end
        end
      end
    end

    context 'shows the most up-to-date course option if the offer may have been changed' do
      examples = %i[
        withdrawn
        with_offer
        with_modified_offer
        with_accepted_offer
        with_declined_offer
        with_declined_by_default_offer
        with_withdrawn_offer
        with_recruited
        with_deferred_offer
      ]

      examples.each do |trait|
        it "for application #{trait}" do
          with_audit(trait) do |audit, _user, _candidate|
            choice = audit.auditable
            choice.update_columns(offered_course_option_id: create(:course_option).id)
            expect(component_for(audit).course_option.id).to eq(choice.offered_option.id)
          end
        end
      end
    end
  end

  it 'does actually render html :)' do
    with_audit(:awaiting_provider_decision) do |audit, _user, _candidate|
      expect(render_inline(component_for(audit)).to_html).to be_present
    end
  end
end