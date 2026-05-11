# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourtPolicy, type: :policy do
  subject { described_class.new(user, court) }

  let(:owner) { create(:user) }
  let(:venue) { create(:venue, owner: owner) }
  let(:court) { create(:court, venue: venue) }

  def grant_permission(staff_user, resource:, action:)
    permission = create(:permission, resource: resource, action: action)
    role       = create(:role, venue: venue)
    create(:role_permission, role: role, permission: permission)
    create(:venue_membership, user: staff_user, venue: venue, role: role)
  end

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

  describe "index? and show?" do
    context "when user is nil" do
      let(:user) { nil }

      it_behaves_like "denies access", :index
      it_behaves_like "denies access", :show
    end

    context "when user is any authenticated user with no venue relationship" do
      let(:user) { create(:user) }

      it_behaves_like "denies access", :index
      it_behaves_like "denies access", :show
    end

    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it_behaves_like "grants access", :index
      it_behaves_like "grants access", :show
    end

    context "when user is the venue owner" do
      let(:user) { owner }

      it_behaves_like "grants access", :index
      it_behaves_like "grants access", :show
    end
  end

  context "when user is nil" do
    let(:user) { nil }

    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a super admin" do
    let(:user) { create(:user, :super_admin) }

    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
  end

  context "when user is the venue owner" do
    let(:user) { owner }

    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
  end

  context "when user is staff with update permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "courts", action: "update") }

    it_behaves_like "grants access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with delete permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "courts", action: "delete") }

    it_behaves_like "grants access", :destroy
    it_behaves_like "denies access", :update
  end

  context "when user is a member of the venue but has no court permissions" do
    let(:user) { create(:user) }

    before do
      role = create(:role, venue: venue)
      create(:venue_membership, user: user, venue: venue, role: role)
    end

    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a regular user with no venue relationship" do
    let(:user) { create(:user) }

    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  describe "create?" do
    context "when user is nil" do
      let(:user) { nil }

      it "denies create" do
        expect(subject.create?).to be false
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user) }

      it "allows create" do
        expect(subject.create?).to be true
      end
    end
  end
end
