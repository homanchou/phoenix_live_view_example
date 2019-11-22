defmodule Demo.Invoicing.Workday do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Invoicing.{Invoice, Workday}

  schema "workdays" do
    field :date, :date
    field :period1_end, :time
    field :period1_start, :time
    field :period2_end, :time
    field :period2_start, :time
    field :hours, :decimal
    belongs_to :invoice, Invoice

    timestamps()
  end

  def changeset(workday, attrs) do
    workday
    |> cast(attrs, [
      :date,
      :period1_start,
      :period1_end,
      :period2_start,
      :period2_end
    ])
    |> validate_required([
      :date,
      :period1_start,
      :period1_end
    ])
    |> validate_period(:period1)
    |> conditionally_validate_period2()
    |> calculate_hours()
  end

  def conditionally_validate_period2(%{valid?: false} = changeset), do: changeset

  def conditionally_validate_period2(changeset) do
    period2_start = changeset |> get_field(:period2_start)
    period2_end = changeset |> get_field(:period2_end)

    case {period2_start, period2_end} do
      {nil, nil} -> changeset
      {nil, _} -> add_error(changeset, :period2_start, "start_at required if end_at specified")
      {_, nil} -> add_error(changeset, :period2_end, "end_at required if start_at specified")
      {_, _} -> changeset |> validate_period(:period2) |> validate_overlapping_periods()
    end
  end

  def validate_overlapping_periods(%{valid?: false} = changeset), do: changeset

  def validate_overlapping_periods(changeset) do
    period1_end = get_field(changeset, :period1_end)
    period2_start = get_field(changeset, :period2_start)

    case Time.compare(period1_end, period2_start) do
      :lt ->
        changeset

      _ ->
        add_error(
          changeset,
          :period2_start,
          "when defined, period2 must come after period1 and not overlap"
        )
    end
  end

  def validate_period(%{valid?: false} = changeset, _prefix), do: changeset

  def validate_period(changeset, prefix) do
    start_at = get_field(changeset, :"#{prefix}_start")
    end_at = get_field(changeset, :"#{prefix}_end")

    if start_at == nil or end_at == nil do
      changeset
    else
      case Time.compare(start_at, end_at) do
        :lt -> changeset
        _ -> add_error(changeset, :"#{prefix}_start", "start_at must be earlier then end_at")
      end
    end
  end

  def calculate_hours(%{valid?: false} = changeset), do: changeset

  def calculate_hours(changeset) do
    period1_start = get_field(changeset, :period1_start)
    period1_end = get_field(changeset, :period1_end)
    period2_start = get_field(changeset, :period2_start)
    period2_end = get_field(changeset, :period2_end)

    hours =
      Decimal.add(
        calculate_hours(period1_start, period1_end),
        calculate_hours(period2_start, period2_end)
      )

    put_change(changeset, :hours, hours)
  end

  def calculate_hours(nil, nil) do
    Decimal.new(0)
  end

  def calculate_hours(start_at, end_at) do
    Time.diff(end_at, start_at) |> Decimal.div(3600)
  end

  def get_attrs(%Workday{} = workday) do
    get_attrs(Workday.changeset(workday, %{}))
  end

  def get_attrs(%Ecto.Changeset{} = changeset) do
    %{
      "date" => Ecto.Changeset.get_field(changeset, :date),
      "period1_start" => Ecto.Changeset.get_field(changeset, :period1_start),
      "period1_end" => Ecto.Changeset.get_field(changeset, :period1_end),
      "period2_start" => Ecto.Changeset.get_field(changeset, :period2_start),
      "period2_end" => Ecto.Changeset.get_field(changeset, :period2_end)
    }
  end
end
