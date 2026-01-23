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

  # Steam-specific tests
  test "steam_provider? returns true for steam provider" do
    identity = Identity.new(provider: "steam", uid: "76561198012345678", user: users(:one))
    assert identity.steam_provider?
  end

  test "steam_provider? returns false for non-steam provider" do
    identity = identities(:one)
    identity.provider = "google"
    assert_not identity.steam_provider?
  end

  test "should validate steam_id format for steam provider" do
    identity = Identity.new(
      provider: "steam",
      uid: "76561198012345678",
      steam_id: "invalid",
      user: users(:one)
    )
    assert_not identity.valid?
    assert_includes identity.errors[:steam_id], "must be a 17-digit Steam ID"
  end

  test "should accept valid 17-digit steam_id" do
    identity = Identity.new(
      provider: "steam",
      uid: "76561198012345678",
      steam_id: "76561198012345678",
      user: users(:one)
    )
    assert identity.valid?
  end

  test "should allow nil steam_id for non-steam providers" do
    identity = Identity.new(
      provider: "google",
      uid: "12345678",
      steam_id: nil,
      user: users(:one)
    )
    assert identity.valid?, identity.errors.full_messages.join(", ")
  end

  test "should validate profile_visibility values" do
    identity = Identity.new(
      provider: "steam",
      uid: "76561198012345678",
      steam_id: "76561198012345678",
      profile_visibility: "invalid_value",
      user: users(:one)
    )
    assert_not identity.valid?
    assert_includes identity.errors[:profile_visibility], "is not included in the list"
  end

  test "public_profile? returns true when visibility is public" do
    identity = Identity.new(profile_visibility: "public")
    assert identity.public_profile?
  end

  test "public_profile? returns false when visibility is not public" do
    identity = Identity.new(profile_visibility: "private")
    assert_not identity.public_profile?
  end

  test "private_profile? returns true when visibility is private" do
    identity = Identity.new(profile_visibility: "private")
    assert identity.private_profile?
  end

  test "profile_visibility_needs_check? returns true when never checked" do
    identity = Identity.new(provider: "steam", profile_last_checked_at: nil)
    assert identity.profile_visibility_needs_check?
  end

  test "profile_visibility_needs_check? returns true when checked over an hour ago" do
    identity = Identity.new(provider: "steam", profile_last_checked_at: 2.hours.ago)
    assert identity.profile_visibility_needs_check?
  end

  test "profile_visibility_needs_check? returns false when checked recently" do
    identity = Identity.new(provider: "steam", profile_last_checked_at: 30.minutes.ago)
    assert_not identity.profile_visibility_needs_check?
  end

  test "profile_visibility_needs_check? returns false for non-steam providers" do
    identity = Identity.new(provider: "google", profile_last_checked_at: nil)
    assert_not identity.profile_visibility_needs_check?
  end

  test "find_or_create_from_omniauth stores steam_id for steam provider" do
    user = users(:one)
    auth_hash = {
      "provider" => "steam",
      "uid" => "76561198012345678",
      "credentials" => {},
      "extra" => {}
    }

    identity = Identity.find_or_create_from_omniauth(auth_hash, user)
    assert_equal "76561198012345678", identity.steam_id
    assert_equal "steam", identity.provider
  end
end
