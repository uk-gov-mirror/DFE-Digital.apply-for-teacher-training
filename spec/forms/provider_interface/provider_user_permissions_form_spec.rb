require 'rails_helper'

RSpec.describe ProviderInterface::ProviderUserPermissionsForm do
  let(:provider) { create(:provider) }
  let(:provider_user) { create(:provider_user, providers: [provider]) }
  let(:view_applications_only) { true }
  let(:permissions) { [] }
  let(:form_params) do
    {
      provider: provider,
      provider_user: provider_user,
      view_applications_only: view_applications_only,
      permissions: permissions,
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:provider_user) }
    it { is_expected.to validate_presence_of(:view_applications_only) }

    describe '#at_least_one_extra_permission_is_set' do
      context 'when view_applications_only is true' do
        it 'does not validate that extra permissions are set' do
          expect(described_class.build_from_params(form_params)).to be_valid
        end
      end

      context 'when view_applications_only is false' do
        let(:view_applications_only) { false }

        it 'validates that extra permissions are set' do
          model = described_class.build_from_params(form_params)
          expect(model).to be_invalid
          expect(model.errors[:permissions]).to contain_exactly('Select extra permissions')
        end
      end
    end
  end

  describe '#build_from_model' do
    let(:provider_permissions) { create(:provider_permissions, make_decisions: true, view_diversity_information: true) }

    it 'generates a form object set to the model\'s permissions' do
      form = described_class.build_from_model(provider_permissions)

      expect(form.permissions).not_to include 'manage_organisations'
      expect(form.permissions).not_to include 'manage_users'
      expect(form.permissions).not_to include 'view_safeguarding_information'
      expect(form.permissions).to include 'view_diversity_information'
      expect(form.permissions).to include 'make_decisions'

      expect(form.view_applications_only).to eq(false)
    end

    context 'when no extra permissions are set on the model' do
      let(:provider_permissions) { create(:provider_permissions) }

      it 'sets view_applications_only to true' do
        form = described_class.build_from_model(provider_permissions)

        expect(form.permissions).to be_empty
        expect(form.view_applications_only).to eq(true)
      end
    end
  end

  describe '#build_from_params' do
    let(:permissions) { %w[manage_organisations manage_users make_decisions] }

    context 'when view_applications_only is false' do
      let(:view_applications_only) { false }

      it 'generates a form object set to the permissions from the params' do
        form = described_class.build_from_params(form_params)

        expect(form.permissions).to match_array(permissions)
      end
    end

    context 'when view_applications_only is true' do
      let(:view_applications_only) { true }

      it 'ignores any permissions passed to the form in the params' do
        form = described_class.build_from_params(form_params)

        expect(form.permissions).to be_empty
      end
    end
  end
end
