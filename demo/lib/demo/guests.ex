defmodule Demo.Guests do
  @moduledoc """
  Guests context
  """
    import Ecto.Query
  alias Demo.Guests.Guest
  alias Demo.Repo
alias Demo.Conferences.Conference

  @doc """
    Search query to find guests associated with a conference. This is innefective on purpose.
  """
  def find_by_conference(%Conference{id: id}) do
    query = from g in Guest, where: g.conference_id == ^id
    Repo.all(query)
  end

end
