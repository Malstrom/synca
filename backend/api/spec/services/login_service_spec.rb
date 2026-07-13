# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoginService do
  let(:password) { "secret123" }
  let!(:user)    { create(:user, email: "test@example.com", password: password) }

  def call(email: "test@example.com", pw: password)
    described_class.call(params: { auth: { email: email, password: pw } })
  end

  describe ".call" do
    context "valid credentials" do
      it "returns Success(user)" do
        result = call
        expect(result).to be_success
        expect(result.value!).to eq(user)
      end

      it "is case-insensitive on email" do
        result = call(email: "TEST@EXAMPLE.COM")
        expect(result).to be_success
      end
    end

    context "wrong password" do
      it "returns Failure[:invalid_credentials]" do
        result = call(pw: "wrongpassword")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:invalid_credentials)
        expect(result.failure.last).to eq(I18n.t("errors.auth.invalid_credentials"))
      end
    end

    context "user not found" do
      it "returns Failure[:invalid_credentials]" do
        result = call(email: "nobody@example.com")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:invalid_credentials)
      end
    end

    context "contract validation" do
      it "returns Failure[:validation_failed] when email is missing" do
        result = described_class.call(params: { auth: { password: password } })
        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation_failed)
      end

      it "returns Failure[:validation_failed] when password is too short" do
        result = call(pw: "short")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation_failed)
      end
    end
  end
end
