defmodule Demo.Repo.Migrations.CreateWorkdays do
  use Ecto.Migration

  def change do
    # an invoice can have many workdays that are invoiced all at once
    # a workday happens on 1 day but can have at most 2 work periods (start and stop time)
    create table(:workdays) do
      add(:date, :date, null: false)
      add(:period1_start, :time, null: false)
      add(:period1_end, :time, null: false)
      add(:period2_start, :time)
      add(:period2_end, :time)
      add(:invoice_id, references(:invoices, on_delete: :delete_all))
      add(:hours, :decimal, scale: 2, precision: 5, default: 0)
      timestamps()
    end

    # you cannot have a duplicate workday for an invoice
    create(unique_index(:workdays, [:invoice_id, :date]))
  end
end
