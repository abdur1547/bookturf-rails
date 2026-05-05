# frozen_string_literal: true

require "rails_helper"

RSpec.describe RolePolicy, type: :policy do
  subject { described_class.new(user, role) }

  let(:owner) { create(:user) }
  let(:venue) { create(:venue, owner: owner) }
  let(:role)  { create(:role, venue: venue) }

  shared_examples "grants access" do |action|
    it "allows #{action}" do
      expect(subject.public_send(:"#{action}?")).to be true
    end
  end

  shared_examples "denies access" do |action|
    it "denies #{action}" do
      expect(subject.public_send(:"#{action}?")).to be false
    end
  end

  context "when user is nil" do
    let(:user) { nil }

    it_behaves_like "denies access", :index
    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a super admin" do
    let(:user) { create(:user, :super_admin) }

    it_behaves_like "grants access", :index
    it_behaves_like "grants access", :show
    it_behaves_like "grants access", :create
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
  end

  context "when user is the venue owner" do
    let(:user) { owner }

    it_behaves_like "grants access", :index
    it_behaves_like "grants access", :show
    it_behaves_like "grants access", :create
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
  end

  context "when user owns a different venue" do
    let(:user)        { create(:user) }
    let(:other_venue) { create(:venue, owner: user) }

    before { other_venue }

    it_behaves_like "grants access", :index
    it_behaves_like "grants access", :create
    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a regular user with no owned venues" do
    let(:user) { create(:user) }

    it_behaves_like "denies access", :index
    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  describe "Scope" do
    subject { described_class::Scope.new(user, Role.all).resolve }

    let(:other_owner) { create(:user) }
    let(:other_venue) { create(:venue, owner: other_owner) }

    before do
      create(:role, venue: venue)
      create(:role, venue: other_venue)
    end

    context "when user is nil" do
      let(:user) { nil }

      it "returns no roles" do
        expect(subject).to be_empty
      end
    end

    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns all roles" do
        expect(subject.count).to eq(Role.count)
      end
    end

    context "when user is the venue owner" do
      let(:user) { owner }

      it "returns only roles for owned venues" do
        expect(subject.map(&:venue_id).uniq).to eq([ venue.id ])
      end
    end

    context "when user has no owned venues" do
      let(:user) { create(:user) }

      it "returns no roles" do
        expect(subject).to be_empty
      end
    end
  end
end
