defmodule Demo.Conferences.Conference do
  use Ecto.Schema
  import Ecto.Changeset

  alias Demo.Guests.Guest

  schema "conferences" do
    field :date, :naive_datetime
    field :description, :string
    field :name, :string
    field :room, :string

    has_many :guests, Guest

    timestamps()
  end

  @doc false
  def changeset(conference, attrs) do
    conference
    |> cast(attrs, [:name, :description, :room, :date])
    |> cast_assoc(:guests)
    |> validate_required([:name, :description, :room, :date])
  end
end
