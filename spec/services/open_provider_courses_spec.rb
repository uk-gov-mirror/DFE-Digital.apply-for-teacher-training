require 'rails_helper'

RSpec.describe OpenProviderCourses do
  let(:provider) { create(:provider, :with_user) }
  let(:mail) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  it 'opens all courses shown on Find for a given provider and emails all provider users' do
    create_list(:course, 2, provider: provider, exposed_in_find: true)
    provider_user = provider.provider_users.first
    allow(ProviderMailer).to receive(:courses_open_on_apply).and_return(mail)

    expect {
      described_class.new(provider: provider).call
    }.to(change { provider.courses.open_on_apply.count }.from(0).to(2))

    expect(ProviderMailer).to have_received(:courses_open_on_apply).with(provider_user).once
  end

  it 'does not open courses that are not exposed in Find' do
    provider = create(:provider)
    create(:course, exposed_in_find: false, provider: provider)

    expect { described_class.new(provider: provider).call }
      .not_to(change { Course.open_on_apply.count })
  end

  it 'opens the correct ratified courses' do
    training_provider = create(:provider)
    accredited_body = create(:provider)
    ratified_course = create(:course, exposed_in_find: true, open_on_apply: false, provider: training_provider, accredited_provider: accredited_body)
    other_course = create(:course, exposed_in_find: true, open_on_apply: false, provider: training_provider, accredited_provider: nil)

    expect {
      described_class.new(provider: accredited_body).call
    }.to(change { ratified_course.reload.open_on_apply? }.from(false).to(true))

    expect(other_course.reload).not_to be_open_on_apply
  end

  it 'creates audits for the changes it makes', with_audited: true do
    provider = create(:provider)
    course = create(:course, exposed_in_find: true, provider: provider)

    expect { described_class.new(provider: provider).call }
      .to(change { course.audits.count }.from(2).to(3))

    expect(course.audits.last.audited_changes.keys).to include('open_on_apply')
  end
end
