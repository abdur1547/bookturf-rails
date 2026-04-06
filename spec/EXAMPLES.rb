# frozen_string_literal: true

# This is a comprehensive example showing RSpec best practices
# Delete this file once you're familiar with the patterns

require 'rails_helper'

# Example: Testing a User model
# Uncomment and adapt when you create a User model

# RSpec.describe User, type: :model do
#   # Using shoulda-matchers for simple validations and associations
#   describe 'validations' do
#     it { should validate_presence_of(:email) }
#     it { should validate_uniqueness_of(:email).case_insensitive }
#     it { should validate_length_of(:password).is_at_least(8) }
#     it { should allow_value('user@example.com').for(:email) }
#     it { should_not allow_value('invalid').for(:email) }
#   end
#
#   describe 'associations' do
#     it { should have_many(:posts).dependent(:destroy) }
#     it { should have_one(:profile).dependent(:destroy) }
#     it { should belong_to(:organization).optional }
#   end
#
#   describe 'database' do
#     it { should have_db_column(:email).of_type(:string) }
#     it { should have_db_index(:email).unique }
#   end
#
#   # Using let for test data
#   describe '#full_name' do
#     let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }
#
#     it 'returns the full name' do
#       expect(user.full_name).to eq('John Doe')
#     end
#
#     context 'when first name is missing' do
#       let(:user) { build(:user, first_name: nil, last_name: 'Doe') }
#
#       it 'returns only the last name' do
#         expect(user.full_name).to eq('Doe')
#       end
#     end
#   end
#
#   # Testing instance methods
#   describe '#admin?' do
#     it 'returns true for admin role' do
#       user = create(:user, :admin)
#       expect(user.admin?).to be true
#     end
#
#     it 'returns false for regular role' do
#       user = create(:user)
#       expect(user.admin?).to be false
#     end
#   end
#
#   # Testing class methods
#   describe '.active' do
#     it 'returns only active users' do
#       active_user = create(:user, active: true)
#       inactive_user = create(:user, active: false)
#
#       expect(User.active).to include(active_user)
#       expect(User.active).not_to include(inactive_user)
#     end
#   end
#
#   # Testing callbacks
#   describe 'callbacks' do
#     describe 'before_save' do
#       it 'downcases email before saving' do
#         user = create(:user, email: 'TEST@EXAMPLE.COM')
#         expect(user.email).to eq('test@example.com')
#       end
#     end
#   end
#
#   # Testing scopes
#   describe 'scopes' do
#     describe '.recent' do
#       it 'returns users created in the last 30 days' do
#         old_user = create(:user, created_at: 31.days.ago)
#         recent_user = create(:user, created_at: 1.day.ago)
#
#         expect(User.recent).to include(recent_user)
#         expect(User.recent).not_to include(old_user)
#       end
#     end
#   end
# end

# Example: Testing a request (preferred over controller specs)
# RSpec.describe 'Users', type: :request do
#   describe 'GET /users' do
#     it 'returns success' do
#       get users_path
#       expect(response).to have_http_status(:success)
#     end
#
#     it 'renders all users' do
#       users = create_list(:user, 3)
#       get users_path
#
#       expect(response.body).to include(users.first.email)
#       expect(response.body).to include(users.last.email)
#     end
#   end
#
#   describe 'GET /users/:id' do
#     let(:user) { create(:user) }
#
#     it 'returns the user' do
#       get user_path(user)
#       expect(response).to have_http_status(:success)
#     end
#
#     context 'when user does not exist' do
#       it 'returns 404' do
#         get user_path(id: 'invalid')
#         expect(response).to have_http_status(:not_found)
#       end
#     end
#   end
#
#   describe 'POST /users' do
#     context 'with valid parameters' do
#       let(:valid_attributes) do
#         {
#           email: 'test@example.com',
#           password: 'password123',
#           first_name: 'John',
#           last_name: 'Doe'
#         }
#       end
#
#       it 'creates a new user' do
#         expect {
#           post users_path, params: { user: valid_attributes }
#         }.to change(User, :count).by(1)
#       end
#
#       it 'redirects to the created user' do
#         post users_path, params: { user: valid_attributes }
#         expect(response).to redirect_to(user_path(User.last))
#       end
#     end
#
#     context 'with invalid parameters' do
#       let(:invalid_attributes) { { email: '' } }
#
#       it 'does not create a new user' do
#         expect {
#           post users_path, params: { user: invalid_attributes }
#         }.not_to change(User, :count)
#       end
#
#       it 'returns unprocessable entity status' do
#         post users_path, params: { user: invalid_attributes }
#         expect(response).to have_http_status(:unprocessable_entity)
#       end
#     end
#   end
#
#   describe 'PATCH /users/:id' do
#     let(:user) { create(:user) }
#     let(:new_attributes) { { first_name: 'Jane' } }
#
#     it 'updates the user' do
#       patch user_path(user), params: { user: new_attributes }
#       user.reload
#       expect(user.first_name).to eq('Jane')
#     end
#
#     it 'redirects to the user' do
#       patch user_path(user), params: { user: new_attributes }
#       expect(response).to redirect_to(user_path(user))
#     end
#   end
#
#   describe 'DELETE /users/:id' do
#     let!(:user) { create(:user) }
#
#     it 'destroys the user' do
#       expect {
#         delete user_path(user)
#       }.to change(User, :count).by(-1)
#     end
#
#     it 'redirects to users list' do
#       delete user_path(user)
#       expect(response).to redirect_to(users_path)
#     end
#   end
# end

# Example: Testing system/feature specs
# RSpec.describe 'User Registration', type: :system do
#   it 'allows a visitor to sign up' do
#     visit new_user_registration_path
#
#     fill_in 'Email', with: 'test@example.com'
#     fill_in 'Password', with: 'password123'
#     fill_in 'Password confirmation', with: 'password123'
#     fill_in 'First name', with: 'John'
#     fill_in 'Last name', with: 'Doe'
#
#     click_button 'Sign Up'
#
#     expect(page).to have_content('Welcome! You have signed up successfully.')
#     expect(page).to have_current_path(root_path)
#   end
#
#   it 'shows validation errors for invalid input' do
#     visit new_user_registration_path
#
#     fill_in 'Email', with: 'invalid'
#     click_button 'Sign Up'
#
#     expect(page).to have_content('Email is invalid')
#   end
#
#   # JavaScript test example
#   it 'validates email format dynamically', js: true do
#     visit new_user_registration_path
#
#     fill_in 'Email', with: 'invalid'
#     find('body').click # Trigger blur event
#
#     expect(page).to have_content('Please enter a valid email')
#   end
# end

# Example: Shared examples for reusable specs
# shared_examples 'a timestamped model' do
#   it { should respond_to(:created_at) }
#   it { should respond_to(:updated_at) }
#
#   it 'sets created_at on creation' do
#     record = described_class.create!(valid_attributes)
#     expect(record.created_at).to be_present
#   end
#
#   it 'updates updated_at on save' do
#     record = create(described_class.name.underscore.to_sym)
#     old_updated_at = record.updated_at
#
#     travel_to 1.hour.from_now do
#       record.touch
#       expect(record.updated_at).to be > old_updated_at
#     end
#   end
# end

# Example: Testing background jobs
# RSpec.describe SendWelcomeEmailJob, type: :job do
#   describe '#perform' do
#     let(:user) { create(:user) }
#
#     it 'sends a welcome email' do
#       expect {
#         described_class.perform_now(user.id)
#       }.to change { ActionMailer::Base.deliveries.count }.by(1)
#     end
#
#     it 'enqueues the job' do
#       expect {
#         described_class.perform_later(user.id)
#       }.to have_enqueued_job(described_class).with(user.id)
#     end
#   end
# end

# Example: Testing mailers
# RSpec.describe UserMailer, type: :mailer do
#   describe '#welcome_email' do
#     let(:user) { create(:user) }
#     let(:mail) { described_class.welcome_email(user) }
#
#     it 'renders the subject' do
#       expect(mail.subject).to eq('Welcome to Our App!')
#     end
#
#     it 'renders the receiver email' do
#       expect(mail.to).to eq([user.email])
#     end
#
#     it 'renders the sender email' do
#       expect(mail.from).to eq(['noreply@example.com'])
#     end
#
#     it 'includes the user name in the body' do
#       expect(mail.body.encoded).to include(user.first_name)
#     end
#   end
# end
