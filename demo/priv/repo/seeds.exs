# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Demo.Repo.insert!(%Demo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Demo.Repo
alias Demo.Conferences
alias Demo.Conferences.Conference
alias Demo.Guests.Guest


## This seeding script is specificaly designed to insert a lot of meaningless data into two tables. The only goal here is to be able to trigger
## N+1 queries in the demo. Better methods to generate dummy data probably exist but it is beyond the point of this script

guests = 1..1000
        |> Enum.map(fn index -> 
            %{ name: "GuestName#{index}",
                    firstname: "FirstName#{1}"                    
                  }
        end)


 1..500
              |> Enum.each(fn index -> 
              %{
              date: DateTime.add(DateTime.now!("Etc/UTC"), index, :day) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second),
              description: "A simple conference, number #{index}",
              name: "A seeding conference, episode #{index}",
              room: "Ballroom",      
              guests: guests
              }
              |> Conferences.create_conference()


  end)




