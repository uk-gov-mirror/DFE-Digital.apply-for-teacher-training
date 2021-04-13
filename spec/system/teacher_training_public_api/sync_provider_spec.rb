require 'rails_helper'

RSpec.describe 'Sync provider', sidekiq: true do
  include TeacherTrainingPublicAPIHelper

  scenario 'Creates and updates providers' do
    given_there_are_2_providers_in_the_teacher_training_api
    and_one_of_the_providers_exists_already

    when_the_sync_runs
    then_it_creates_one_provider
    and_it_updates_another
    and_it_sets_the_last_synced_timestamp
  end

  def given_there_are_2_providers_in_the_teacher_training_api
    stub_teacher_training_api_providers(
      specified_attributes: [
        {
          code: 'ABC',
          name: 'ABC College',
        },
        {
          code: 'DEF',
          name: 'DER College',
        },
      ],
    )
  end

  def and_one_of_the_providers_exists_already
    create(:provider, code: 'DEF', name: 'DEF College')
  end

  def when_the_sync_runs
    allow(TeacherTrainingPublicAPI::SyncSubjects).to receive(:perform_async)

    TeacherTrainingPublicAPI::SyncAllProvidersAndCoursesWorker.perform_async
  end

  def then_it_creates_one_provider
    expect(Provider.find_by(code: 'ABC')).not_to be_nil
  end

  def and_it_updates_another
    expect(Provider.find_by(code: 'DEF').name).to eql('DER College')
  end

  def and_it_sets_the_last_synced_timestamp
    expect(TeacherTrainingPublicAPI::SyncCheck.last_sync).not_to be_blank
  end
end
