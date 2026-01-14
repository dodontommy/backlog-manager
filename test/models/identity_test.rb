require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "should belong to user" do
    identity = identities(:one)
    assert_respond_to identity, :user
  end

  test "should require provider" do
    identity = Identity.new(uid: "12345")
    assert_not identity.valid?
    assert_includes identity.errors[:provider], "can't be blank"
  end

  test "should require uid" do
    identity = Identity.new(provider: "google")
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "can't be blank"
  end

  test "should enforce unique uid per provider" do
    existing = identities(:one)
    identity = Identity.new(
      provider: existing.provider,
      uid: existing.uid,
      user: users(:two)
    )
    assert_not identity.valid?
  end

  test "expired? returns true when token is expired" do
    identity = identities(:one)
    identity.expires_at = 1.day.ago
    assert identity.expired?
  end

  test "expired? returns false when token is not expired" do
    identity = identities(:one)
    identity.expires_at = 1.day.from_now
    assert_not identity.expired?
  end

  test "expired? returns false when expires_at is nil" do
    identity = identities(:one)
    identity.expires_at = nil
    assert_not identity.expired?
  end
end
