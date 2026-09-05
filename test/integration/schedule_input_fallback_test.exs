defmodule PhoenixKitPosts.Integration.ScheduleInputFallbackTest do
  @moduledoc """
  `ScheduleInput.editor_tz/1`'s site fallback needs the settings table, so
  it lives in the integration tier; the pure conversions are in
  `test/schedule_input_test.exs`.
  """
  use PhoenixKitPosts.DataCase, async: false

  alias PhoenixKitPosts.Web.ScheduleInput

  test "no profile value — nil, blank, a map without the column, no user — is the site setting" do
    site = PhoenixKit.Settings.get_setting("time_zone", "0")
    assert ScheduleInput.editor_tz(%{user_timezone: nil}) == site
    assert ScheduleInput.editor_tz(%{user_timezone: ""}) == site
    assert ScheduleInput.editor_tz(%{uuid: "partial"}) == site
    assert ScheduleInput.editor_tz(nil) == site
  end
end
