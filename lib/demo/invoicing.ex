defmodule Demo.Invoicing do
  import Ecto.Query, warn: false
  alias Demo.Repo

  alias Demo.Invoicing.Invoice
  alias Demo.Invoicing.Workday

  def list_invoices() do
    Repo.all(
      from i in Invoice,
        join: w in assoc(i, :workdays),
        preload: [workdays: w],
        order_by: [asc: w.date]
    )
  end

  def save_invoice_changeset(changeset) do
    if changeset.data.id do
      Repo.update(changeset)
    else
      Repo.insert(changeset)
    end
  end

  def remove_workday_by_index(changeset, index) do
    workdays = Ecto.Changeset.get_change(changeset, :workdays) || []
    new_workdays = List.delete_at(workdays, index)
    Ecto.Changeset.put_change(changeset, :workdays, new_workdays) |> Invoice.calc_totals()
  end

  def new_invoice() do
    changeset =
      Invoice.changeset(
        %Invoice{
          hourly_rate: Decimal.new("18")
        },
        %{}
      )

    add_default_workday(changeset)
  end

  def add_default_workday(changeset) do
    workday_attrs = %{
      "date" => Date.utc_today(),
      "period1_start" => "08:00",
      "period1_end" => "20:00"
    }

    insert_workday_into_invoice_changeset(changeset, workday_attrs)
  end

  # when live editing an invoice, add a new workday after the last workday
  def add_new_workday(invoice_changeset) do
    workdays = Ecto.Changeset.get_field(invoice_changeset, :workdays)

    case workdays do
      nil -> add_default_workday(invoice_changeset)
      [] -> add_default_workday(invoice_changeset)
      list -> List.last(list) |> copy_append(invoice_changeset)
    end
  end

  def copy_append(workday, invoice_changeset) do
    workday_attrs = Workday.get_attrs(workday)
    date = workday_attrs["date"]
    workday_attrs = %{workday_attrs | "date" => Date.add(date, 1)}

    insert_workday_into_invoice_changeset(invoice_changeset, workday_attrs)
  end

  def insert_workday_into_invoice_changeset(changeset, new_workday_attrs) do
    workdays = Ecto.Changeset.get_change(changeset, :workdays) || []
    workdays_as_attrs = Enum.map(workdays, fn workday -> Workday.get_attrs(workday) end)

    workdays_as_attrs =
      workdays_as_attrs ++
        [
          new_workday_attrs
        ]

    Invoice.changeset(changeset, %{"workdays" => workdays_as_attrs})
  end
end
