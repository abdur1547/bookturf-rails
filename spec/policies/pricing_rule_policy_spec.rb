# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricingRulePolicy, type: :policy do
  subject { described_class.new(user, pricing_rule) }

  let(:owner)       { create(:user) }
  let(:venue)       { create(:venue, owner: owner) }
  let(:court)       { create(:court, venue: venue) }
  let(:pricing_rule) { create(:pricing_rule, venue: venue, court: court) }

  def grant_permission(staff_user, resource:, action:)
    permission   = create(:permission, resource: resource, action: action)
    role         = create(:role, venue: venue)
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

  context "when user is staff with read permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "pricing", action: "read") }

    it_behaves_like "grants access", :index
    it_behaves_like "grants access", :show
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with create permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "pricing", action: "create") }

    it_behaves_like "grants access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with update permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "pricing", action: "update") }

    it_behaves_like "grants access", :update
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with delete permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "pricing", action: "delete") }

    it_behaves_like "grants access", :destroy
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
  end

  context "when user is a member of the venue but has no pricing permissions" do
    let(:user) { create(:user) }

    before do
      role = create(:role, venue: venue)
      create(:venue_membership, user: user, venue: venue, role: role)
    end

    it_behaves_like "denies access", :index
    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a regular user with no venue relationship" do
    let(:user) { create(:user) }

    it_behaves_like "denies access", :index
    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  describe "Scope" do
    let(:other_owner) { create(:user) }
    let(:other_venue) { create(:venue, owner: other_owner) }
    let(:other_court) { create(:court, venue: other_venue) }

    before do
      create(:pricing_rule, venue: venue, court: court)
      create(:pricing_rule, venue: other_venue, court: other_court)
    end

    subject { described_class::Scope.new(user, PricingRule.all).resolve }

    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns all pricing rules" do
        expect(subject.count).to eq(PricingRule.count)
      end
    end

    context "when user is nil" do
      let(:user) { nil }

      it "returns no pricing rules" do
        expect(subject).to be_empty
      end
    end

    context "when user is the venue owner" do
      let(:user) { owner }

      it "returns only pricing rules for owned venues" do
        expect(subject.map(&:venue_id).uniq).to eq([ venue.id ])
      end
    end

    context "when user is staff at the venue" do
      let(:user) { create(:user) }

      before do
        role = create(:role, venue: venue)
        create(:venue_membership, user: user, venue: venue, role: role)
      end

      it "returns pricing rules for venues where the user is a member" do
        expect(subject.map(&:venue_id).uniq).to eq([ venue.id ])
      end
    end

    context "when user has no venue relationship" do
      let(:user) { create(:user) }

      it "returns no pricing rules" do
        expect(subject).to be_empty
      end
    end
  end
end
