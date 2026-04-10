require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:refresh_tokens).dependent(:delete_all) }
    it { should have_many(:blacklisted_tokens).dependent(:delete_all) }
    it { should have_many(:password_reset_tokens).dependent(:delete_all) }
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:roles).through(:user_roles) }

    # Phase 2: Venue associations
    it { should have_many(:owned_venues).class_name('Venue').with_foreign_key('owner_id').dependent(:restrict_with_error) }
    it { should have_many(:venue_users).dependent(:destroy) }
    it { should have_many(:venues).through(:venue_users) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it 'validates first_name length' do
      user = build(:user, first_name: 'a')
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates last_name length' do
      user = build(:user, last_name: 'a')
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates phone number format' do
      user = build(:user, phone_number: 'invalid')
      expect(user).not_to be_valid
      expect(user.errors[:phone_number]).to be_present
    end

    it 'allows valid phone number' do
      user = build(:user, phone_number: '+92 300 1234567')
      expect(user).to be_valid
    end

    it 'allows blank phone number' do
      user = build(:user, phone_number: nil)
      expect(user).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_user) { create(:user, is_active: true) }
    let!(:inactive_user) { create(:user, :inactive) }
    let!(:global_admin) { create(:user, :global_admin) }

    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user, global_admin)
        expect(User.active).not_to include(inactive_user)
      end
    end

    describe '.inactive' do
      it 'returns only inactive users' do
        expect(User.inactive).to include(inactive_user)
        expect(User.inactive).not_to include(active_user, global_admin)
      end
    end

    describe '.global_admins' do
      it 'returns only global admins' do
        expect(User.global_admins).to include(global_admin)
        expect(User.global_admins).not_to include(active_user, inactive_user)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns combined first and last name' do
        expect(user.full_name).to eq('John Doe')
      end
    end

    describe '#activate!' do
      it 'sets is_active to true' do
        user.update(is_active: false)
        expect { user.activate! }.to change { user.is_active }.from(false).to(true)
      end
    end

    describe '#deactivate!' do
      it 'sets is_active to false' do
        expect { user.deactivate! }.to change { user.is_active }.from(true).to(false)
      end
    end
  end

  describe 'role and permission methods' do
    let(:user) { create(:user) }
    let(:owner_role) { create(:role, :owner) }
    let(:customer_role) { create(:role, :customer) }
    let(:admin_role) { create(:role, :admin) }
    let(:create_bookings_permission) { create(:permission, :create_bookings) }
    let(:manage_bookings_permission) { create(:permission, :manage_bookings) }

    describe '#assign_role' do
      it 'assigns role to user' do
        expect { user.assign_role(customer_role) }
          .to change { user.roles.count }.by(1)
        expect(user.roles).to include(customer_role)
      end

      it 'does not duplicate role assignment' do
        user.assign_role(customer_role)
        expect { user.assign_role(customer_role) }
          .not_to change { user.user_roles.count }
      end

      it 'records who assigned the role' do
        assigner = create(:user)
        user.assign_role(customer_role, assigned_by: assigner)
        user_role = user.user_roles.last
        expect(user_role.assigned_by).to eq(assigner)
      end
    end

    describe '#remove_role' do
      before { user.assign_role(customer_role) }

      it 'removes role from user' do
        expect { user.remove_role(customer_role) }
          .to change { user.roles.count }.by(-1)
        expect(user.roles).not_to include(customer_role)
      end

      it 'does nothing if user does not have role' do
        expect { user.remove_role(admin_role) }
          .not_to change { user.roles.count }
      end
    end

    describe '#has_role?' do
      it 'returns true when user has role' do
        user.assign_role(customer_role)
        expect(user.has_role?('customer')).to be true
      end

      it 'returns false when user does not have role' do
        expect(user.has_role?('admin')).to be false
      end
    end

    describe '#has_permission?' do
      before do
        customer_role.add_permission(create_bookings_permission)
        user.assign_role(customer_role)
      end

      it 'returns true when user has specific permission' do
        expect(user.has_permission?('create:bookings')).to be true
      end

      it 'returns false when user lacks permission' do
        expect(user.has_permission?('delete:venues')).to be false
      end
    end

    describe '#permissions' do
      before do
        customer_role.add_permission(create_bookings_permission)
        user.assign_role(customer_role)
      end

      it 'returns all permissions from all roles' do
        expect(user.permissions).to include(create_bookings_permission)
      end

      it 'returns distinct permissions' do
        admin_role.add_permission(create_bookings_permission)
        user.assign_role(admin_role)
        expect(user.permissions.count).to eq(1)
      end
    end

    describe '#can?' do
      context 'with specific permission' do
        before do
          customer_role.add_permission(create_bookings_permission)
          user.assign_role(customer_role)
        end

        it 'returns true when user has permission' do
          expect(user.can?(:create, :bookings)).to be true
        end

        it 'returns false when user lacks permission' do
          expect(user.can?(:delete, :venues)).to be false
        end
      end

      context 'with manage permission' do
        before do
          admin_role.add_permission(manage_bookings_permission)
          user.assign_role(admin_role)
        end

        it 'returns true for any action on managed resource' do
          expect(user.can?(:create, :bookings)).to be true
          expect(user.can?(:read, :bookings)).to be true
          expect(user.can?(:update, :bookings)).to be true
          expect(user.can?(:delete, :bookings)).to be true
        end
      end
    end

    describe 'role helper methods' do
      it '#owner? returns true for owners' do
        user.assign_role(owner_role)
        expect(user.owner?).to be true
      end

      it '#admin? returns true for admins' do
        user.assign_role(admin_role)
        expect(user.admin?).to be true
      end

      it '#receptionist? returns true for receptionists' do
        receptionist_role = create(:role, :receptionist)
        user.assign_role(receptionist_role)
        expect(user.receptionist?).to be true
      end

      it '#staff? returns true for staff' do
        staff_role = create(:role, :staff)
        user.assign_role(staff_role)
        expect(user.staff?).to be true
      end

      it '#customer? returns true for customers' do
        user.assign_role(customer_role)
        expect(user.customer?).to be true
      end

      it 'returns false for roles not assigned' do
        expect(user.owner?).to be false
        expect(user.admin?).to be false
        expect(user.receptionist?).to be false
        expect(user.staff?).to be false
        expect(user.customer?).to be false
      end
    end
  end
end
