defmodule Demo.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add(:hourly_rate, :decimal, precision: 5, scale: 2, default: 0.0, null: false)
      add(:total, :decimal, precision: 10, scale: 2, default: 0.00)
      add(:hours, :decimal, precision: 5, scale: 2, default: 0)
      timestamps()
    end
  end
end
