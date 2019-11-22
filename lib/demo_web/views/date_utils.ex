defmodule DemoWeb.DateUtils do
  def invoice_date_range(invoice) do
    # invoice |> Repo.preload(:workdays)
    case invoice.workdays do
      [] ->
        ""

      [workday] ->
        date_format(workday.date)

      workdays when is_list(workdays) ->
        first_workday = List.first(workdays)
        last_workday = List.last(workdays)

        "From #{date_format(first_workday.date)} to #{date_format(last_workday.date)}"

      _ ->
        "(Workdays was not loaded)"
    end
  end

  def date_format(date) do
    case Calendar.Strftime.strftime(date, "%b %d, %Y") do
      {:ok, formatted_date} -> formatted_date
      _ -> "invalid_date"
    end
  end

  def time_format(nil), do: "--------------"

  def time_format(time) do
    case Calendar.Strftime.strftime(time, "%I:%M %p") do
      {:ok, formatted_time} -> formatted_time
      _ -> "invalid_time"
    end
  end

  def optional_time_options() do
    [{"Optional", ""} | time_options()]
  end

  def time_options(opts \\ []) do
    minute_options = opts[:minute_options] || ["00", "15", "30", "45"]
    hour_range = opts[:hour_range] || 7..23

    hour_options =
      Enum.to_list(hour_range)
      |> Enum.map(fn i -> hour_tuple(i) end)

    for {padded_24_hour, padded_12_hour, am_pm} <- hour_options,
        padded_minute <- minute_options do
      {"#{padded_12_hour}:#{padded_minute}#{am_pm}", "#{padded_24_hour}:#{padded_minute}"}
    end
  end

  # hour_tuple takes hour integer and returns tuple {24hr, 12hr, am/pm} format
  def hour_tuple(hour_int) do
    {pad_double(hour_int), hour_int_to_string(hour_int), get_am_pm(hour_int)}
  end

  def hour_int_to_string(hour_int) do
    cond do
      hour_int > 23 ->
        :invalid_hour

      0 == hour_int ->
        "12"

      12 == hour_int ->
        "12"

      hour_int > 11 ->
        pad_double(hour_int - 12)

      true ->
        pad_double(hour_int)
    end
  end

  def pad_double(hour_int) do
    hour_int |> Integer.to_string() |> String.pad_leading(2, "0")
  end

  def get_am_pm(hour_int) do
    cond do
      0 == hour_int -> "am"
      12 == hour_int -> "pm"
      hour_int < 12 -> "am"
      true -> "pm"
    end
  end

  def form_to_time(%{data: data, params: params}, field) when is_atom(field) do
    case Map.get(params, to_string(field)) do
      nil ->
        case Map.get(data, field) do
          %{hour: h, minute: m} -> "#{pad_double(h)}:#{pad_double(m)}"
          _ -> nil
        end

      %{hour: h, minute: m} ->
        "#{pad_double(h)}:#{pad_double(m)}"

      hours_and_minutes_string ->
        hours_and_minutes_string
    end
  end
end
