defmodule PhoenixKitPosts.Web.ScheduleInputTest do
  @moduledoc """
  The post editor's `scheduled_at` round trip: the input is the editor's wall
  clock, storage is UTC, and a named zone is resolved on the date typed.
  """
  use ExUnit.Case, async: true

  alias PhoenixKitPosts.Web.ScheduleInput

  defp editor(tz), do: %{user_timezone: tz}

  describe "from_input/2" do
    test "an IANA zone follows daylight saving on the date typed" do
      # Tallinn is +2 in January and +3 in July — the old integer parse read
      # the id as 0 and scheduled both at 10:00 UTC.
      assert ScheduleInput.from_input("2026-01-15T10:00", editor("Europe/Tallinn")) ==
               {:ok, ~U[2026-01-15 08:00:00Z]}

      assert ScheduleInput.from_input("2026-07-15T10:00", editor("Europe/Tallinn")) ==
               {:ok, ~U[2026-07-15 07:00:00Z]}
    end

    test "a legacy offset is fixed, fractional included" do
      assert ScheduleInput.from_input("2026-07-15T10:00", editor("2")) ==
               {:ok, ~U[2026-07-15 08:00:00Z]}

      assert ScheduleInput.from_input("2026-07-15T10:00", editor("5.5")) ==
               {:ok, ~U[2026-07-15 04:30:00Z]}
    end

    test "junk and blanks are :error, never a silent UTC" do
      assert ScheduleInput.from_input("not a date", editor("Europe/Tallinn")) == :error
      assert ScheduleInput.from_input("", editor("Europe/Tallinn")) == :error
      assert ScheduleInput.from_input(nil, editor("Europe/Tallinn")) == :error
    end
  end

  describe "to_input/2" do
    test "renders the stored instant in the editor's zone, per season" do
      assert ScheduleInput.to_input(~U[2026-01-15 08:00:00Z], editor("Europe/Tallinn")) ==
               "2026-01-15T10:00"

      assert ScheduleInput.to_input(~U[2026-07-15 07:00:00Z], editor("Europe/Tallinn")) ==
               "2026-07-15T10:00"

      assert ScheduleInput.to_input(~N[2026-07-15 07:00:00], editor("Europe/Tallinn")) ==
               "2026-07-15T10:00"

      assert ScheduleInput.to_input(nil, editor("Europe/Tallinn")) == nil
    end

    test "round-trips across seasons and zone kinds" do
      for utc <- [~U[2026-01-15 21:30:00Z], ~U[2026-07-15 21:30:00Z]],
          tz <- ["Europe/Tallinn", "America/New_York", "5.5", "0"] do
        input = ScheduleInput.to_input(utc, editor(tz))
        assert ScheduleInput.from_input(input, editor(tz)) == {:ok, utc}, "#{tz} #{utc}"
      end
    end
  end
end
