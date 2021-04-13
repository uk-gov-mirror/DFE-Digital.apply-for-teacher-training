require 'rails_helper'

RSpec.describe TeacherTrainingPublicAPI::SyncAllProvidersAndCoursesWorker do
  describe '#perform' do
    it 'calls the SyncSubjects service' do
      allow(TeacherTrainingPublicAPI::SyncAllProvidersAndCourses).to receive(:call)
      allow(TeacherTrainingPublicAPI::SyncSubjects).to receive(:perform_async)

      described_class.new.perform
      expect(TeacherTrainingPublicAPI::SyncSubjects).to have_received(:perform_async)
    end
  end
end
