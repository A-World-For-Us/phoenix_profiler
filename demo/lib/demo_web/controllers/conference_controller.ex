defmodule DemoWeb.ConferenceController do
  use DemoWeb, :controller

  alias Demo.Conferences
  alias Demo.Conferences.Conference

  def index(conn, _params) do
    conferences = Conferences.list_conferences()
    render(conn, :index, conferences: conferences)
  end

  @doc """
    Special route dedicated to N+1 query triggering, ineffective on purpose.
  """
  def index_plus_one(conn, _params) do
    conferences = Conferences.list_conferences() |> Enum.take(100)

    conferences =
      conferences
      |> Enum.map(fn conference ->
        Map.put(conference, :guests, Demo.Guests.find_by_conference(conference))
      end)

    render(conn, :index, conferences: conferences)
  end

  def new(conn, _params) do
    changeset = Conferences.change_conference(%Conference{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"conference" => conference_params}) do
    case Conferences.create_conference(conference_params) do
      {:ok, conference} ->
        conn
        |> put_flash(:info, "Conference created successfully.")
        |> redirect(to: ~p"/conferences/#{conference}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    conference = Conferences.get_conference!(id)
    render(conn, :show, conference: conference)
  end

  def edit(conn, %{"id" => id}) do
    conference = Conferences.get_conference!(id)
    changeset = Conferences.change_conference(conference)
    render(conn, :edit, conference: conference, changeset: changeset)
  end

  def update(conn, %{"id" => id, "conference" => conference_params}) do
    conference = Conferences.get_conference!(id)

    case Conferences.update_conference(conference, conference_params) do
      {:ok, conference} ->
        conn
        |> put_flash(:info, "Conference updated successfully.")
        |> redirect(to: ~p"/conferences/#{conference}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, conference: conference, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    conference = Conferences.get_conference!(id)
    {:ok, _conference} = Conferences.delete_conference(conference)

    conn
    |> put_flash(:info, "Conference deleted successfully.")
    |> redirect(to: ~p"/conferences")
  end
end
