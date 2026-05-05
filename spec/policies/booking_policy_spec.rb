# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingPolicy, type: :policy do
  let(:owner)        { create(:user) }
  let(:booking_user) { create(:user) }
  let(:venue)        { create(:venue, owner: owner) }
  let(:court)        { build_stubbed(:court, venue: venue) }
  let(:booking)      { build_stubbed(:booking, venue: venue, court: court, user: booking_user) }

  subject { described_class.new(user, booking) }

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

  context "when user is nil" do
    let(:user) { nil }

    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
    it_behaves_like "denies access", :cancel
    it_behaves_like "denies access", :check_in
    it_behaves_like "denies access", :reschedule
  end

  context "when user is a super admin" do
    let(:user) { create(:user, :super_admin) }

    it_behaves_like "grants access", :show
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
    it_behaves_like "grants access", :cancel
    it_behaves_like "grants access", :check_in
    it_behaves_like "grants access", :reschedule
  end

  context "when user is the venue owner" do
    let(:user) { owner }

    it_behaves_like "grants access", :show
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
    it_behaves_like "grants access", :cancel
    it_behaves_like "grants access", :check_in
    it_behaves_like "grants access", :reschedule
  end

  context "when user is the booking owner" do
    let(:user) { booking_user }

    it_behaves_like "grants access", :show
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
    it_behaves_like "grants access", :cancel
    it_behaves_like "grants access", :reschedule

    it_behaves_like "denies access", :check_in
  end

  context "when user is staff with read permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "bookings", action: "read") }

    it_behaves_like "grants access", :show
    it_behaves_like "denies access", :check_in
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with update permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "bookings", action: "update") }

    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :reschedule
    it_behaves_like "denies access", :check_in
    it_behaves_like "denies access", :destroy
  end

  context "when user is staff with manage permission" do
    let(:user) { create(:user) }

    before { grant_permission(user, resource: "bookings", action: "manage") }

    it_behaves_like "grants access", :destroy
    it_behaves_like "grants access", :cancel
    it_behaves_like "grants access", :check_in
  end

  context "when user is a member of the venue but has no booking permissions" do
    let(:user) { create(:user) }

    before do
      role = create(:role, venue: venue)
      create(:venue_membership, user: user, venue: venue, role: role)
    end

    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
    it_behaves_like "denies access", :check_in
  end

  context "when user is a regular user with no venue relationship" do
    let(:user) { create(:user) }

    it_behaves_like "denies access", :show
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
    it_behaves_like "denies access", :check_in
  end

  describe "index? and create?" do
    context "when user is nil" do
      let(:user) { nil }

      subject { described_class.new(user, Booking) }

      it "denies index" do
        expect(subject.index?).to be false
      end

      it "denies create" do
        expect(subject.create?).to be false
      end
    end

    context "when user is present" do
      let(:user) { create(:user) }

      subject { described_class.new(user, Booking) }

      it "grants index" do
        expect(subject.index?).to be true
      end

      it "grants create" do
        expect(subject.create?).to be true
      end
    end
  end
end
