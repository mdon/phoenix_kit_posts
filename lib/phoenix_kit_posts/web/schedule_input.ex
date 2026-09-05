defmodule PhoenixKitPosts.Web.ScheduleInput do
  @moduledoc """
  The `scheduled_at` field of the post editor is a `datetime-local` input:
  a wall clock with no zone. It is read and written in the EDITOR's timezone
  — their profile value, else the site's `time_zone` setting, else UTC
  (core's `PhoenixKit.Utils.Date.get_user_timezone/1`) — and stored as a UTC
  instant.

  Both directions go through core's per-instant helpers, so a named zone
  (`Europe/Warsaw`) follows daylight saving on the date typed, and a legacy
  fixed offset (`"2"`) still works. This used to be an `Integer.parse/1` of
  the profile value that read an IANA id as 0 and ignored the site setting:
  a post scheduled for 09:00 by a Tallinn editor went out at 09:00 UTC.
  """

  alias PhoenixKit.Utils.Date, as: DateUtils

  @doc """
  The editor's timezone value (an IANA id or a legacy offset): their own
  when set, else the site's — core's `get_user_timezone/1` rule, with a
  blank value and a user map without the column both counting as "not set"
  (core's newer releases read a blank the same way).
  """
  @spec editor_tz(map() | nil) :: String.t()
  def editor_tz(user) do
    case user do
      %{user_timezone: tz} when is_binary(tz) and tz != "" -> tz
      _ -> DateUtils.get_user_timezone(%{user_timezone: nil})
    end
  end

  @doc "A stored UTC instant as the input's value in the editor's zone."
  @spec to_input(DateTime.t() | NaiveDateTime.t() | nil, map() | nil) :: String.t() | nil
  def to_input(nil, _user), do: nil

  def to_input(%DateTime{} = dt, user), do: DateUtils.format_datetime_local(dt, editor_tz(user))

  def to_input(%NaiveDateTime{} = naive, user),
    do: to_input(DateTime.from_naive!(naive, "Etc/UTC"), user)

  def to_input(_other, _user), do: nil

  @doc """
  The input's value, read as the editor's wall clock, as a UTC instant.
  `{:ok, datetime}`, or `:error` for anything unparseable.
  """
  @spec from_input(String.t() | nil, map() | nil) :: {:ok, DateTime.t()} | :error
  def from_input(value, user) when is_binary(value) and value != "" do
    case DateUtils.parse_datetime_local(value, editor_tz(user)) do
      {:ok, utc} -> {:ok, utc}
      _ -> :error
    end
  end

  def from_input(_value, _user), do: :error
end
