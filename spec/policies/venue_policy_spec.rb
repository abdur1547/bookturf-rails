# frozen_string_literal: true

require "rails_helper"

RSpec.describe VenuePolicy, type: :policy do
  subject { described_class.new(user, venue) }

  let(:owner) { create(:user) }
  let(:venue) { create(:venue, owner: owner) }

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

      it_behaves_like "grants access", :index
      it_behaves_like "grants access", :show
    end

    context "when user is any authenticated user" do
      let(:user) { create(:user) }

      it_behaves_like "grants access", :index
      it_behaves_like "grants access", :show
    end
  end

  context "when user is nil" do
    let(:user) { nil }

    it_behaves_like "denies access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is a super admin" do
    let(:user) { create(:user, :super_admin) }

    it_behaves_like "grants access", :create
    it_behaves_like "grants access", :update
    it_behaves_like "denies access", :destroy
  end

  context "when user is the venue owner" do
    let(:user) { owner }

    it_behaves_like "grants access", :create
    it_behaves_like "grants access", :update
    it_behaves_like "grants access", :destroy
  end

  context "when user is authenticated but not the venue owner" do
    let(:user) { create(:user) }

    it_behaves_like "grants access", :create
    it_behaves_like "denies access", :update
    it_behaves_like "denies access", :destroy
  end
end
