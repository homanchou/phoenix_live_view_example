defmodule DemoWeb.InvoiceLive.New do
  use Phoenix.LiveView

  alias Demo.Invoicing
  alias Demo.Invoicing.Invoice
  alias DemoWeb.Router.Helpers, as: Routes

  def mount(_session, socket) do
    {:ok,
     assign(socket, %{
       changeset: Invoicing.new_invoice()
     })}
  end

  def handle_event("add_workday", _params, socket) do
    changeset = socket.assigns.changeset
    new_changeset = Invoicing.add_new_workday(changeset)
    {:noreply, assign(socket, changeset: new_changeset)}
  end

  def handle_event("change", %{"invoice" => params}, socket) do
    changeset = %{socket.assigns.changeset | valid?: true, errors: [], action: :insert}
    changeset = Invoice.changeset(changeset, params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"invoice" => _params}, socket) do
    case Invoicing.save_invoice_changeset(socket.assigns.changeset) do
      {:ok, _invoice} ->
        {:stop,
         socket
         |> redirect(to: Routes.invoice_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event(
        "delete_workday",
        %{"workday_id" => "invoice_workdays_" <> workday_index},
        socket
      ) do
    changeset = socket.assigns.changeset
    {index, _} = Integer.parse(workday_index)
    new_changeset = Invoicing.remove_workday_by_index(changeset, index)
    {:noreply, assign(socket, changeset: new_changeset)}
  end

  def render(assigns), do: DemoWeb.InvoiceView.render("new.html", assigns)
end
