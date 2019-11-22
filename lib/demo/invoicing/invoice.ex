defmodule Demo.Invoicing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Invoicing.Workday

  schema "invoices" do
    field :hourly_rate, :decimal, default: Decimal.new(0)
    field :total, :decimal, default: Decimal.new(0)
    field :hours, :decimal, default: Decimal.new(0)
    has_many :workdays, Workday, on_replace: :delete
    timestamps()
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :total,
      :hours,
      :hourly_rate
    ])
    |> cast_assoc(:workdays)
    |> validate_unique_workday_dates()
    |> calc_totals()
  end

  def validate_unique_workday_dates(%{valid?: false} = changeset), do: changeset
  # can only validate the workdays if they are given (if not preloaded then can't validate)
  def validate_unique_workday_dates(changeset) do
    workdays = changeset |> get_field(:workdays)
    unique_dates = Enum.map(workdays, fn w -> w.date end) |> Enum.uniq()

    if length(workdays) == length(unique_dates) do
      changeset
    else
      add_error(changeset, :workdays, "Duplicate date within workdays")
    end
  end

  def calc_totals(%{valid?: false} = changeset),
    do: %{changeset | data: %{changeset.data | total: nil}}

  def calc_totals(changeset) do
    workdays = changeset |> get_field(:workdays)
    rate = get_field(changeset, :hourly_rate)

    total_hours =
      workdays
      |> Enum.reduce(Decimal.new(0), fn workday, acc -> Decimal.add(acc, workday.hours) end)

    changeset = put_change(changeset, :hours, total_hours)

    put_change(changeset, :total, Decimal.mult(rate, total_hours))
  end
end
