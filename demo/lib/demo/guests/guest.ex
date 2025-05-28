defmodule Demo.Guests.Guest do
  @moduledoc """
  Schema file to represent a guest for a conference.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Demo.Conferences.Conference

  schema "guests" do
    field :name, :string
    field :firstname, :string

    belongs_to :conference, Conference

    timestamps()
  end

  @doc false
  def changeset(conference, attrs) do
    conference
    |> cast(attrs, [:name, :firstname])
  end
end
