defmodule DemoWeb.InvoiceController do
  use DemoWeb, :controller
  alias Demo.Invoicing
  alias Phoenix.LiveView

  def index(conn, _params) do
    invoices = Invoicing.list_invoices()
    render(conn, "index.html", %{invoices: invoices})
  end

  def new(conn, _params) do
    conn
    |> put_layout(:app)
    |> LiveView.Controller.live_render(DemoWeb.InvoiceLive.New, session: %{})
  end
end
