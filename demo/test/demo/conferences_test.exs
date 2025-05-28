defmodule Demo.ConferencesTest do
  use Demo.DataCase

  alias Demo.Conferences

  describe "conferences" do
    alias Demo.Conferences.Conference

    import Demo.ConferencesFixtures

    @invalid_attrs %{date: nil, description: nil, name: nil, room: nil}

    test "list_conferences/0 returns all conferences" do
      conference = conference_fixture()
      assert Conferences.list_conferences() == [conference]
    end

    test "get_conference!/1 returns the conference with given id" do
      conference = conference_fixture()
      assert Conferences.get_conference!(conference.id) == conference
    end

    test "create_conference/1 with valid data creates a conference" do
      valid_attrs = %{
        date: ~N[2023-06-18 13:33:00],
        description: "some description",
        name: "some name",
        room: "some room"
      }

      assert {:ok, %Conference{} = conference} = Conferences.create_conference(valid_attrs)
      assert conference.date == ~N[2023-06-18 13:33:00]
      assert conference.description == "some description"
      assert conference.name == "some name"
      assert conference.room == "some room"
    end

    test "create_conference/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conferences.create_conference(@invalid_attrs)
    end

    test "update_conference/2 with valid data updates the conference" do
      conference = conference_fixture()

      update_attrs = %{
        date: ~N[2023-06-19 13:33:00],
        description: "some updated description",
        name: "some updated name",
        room: "some updated room"
      }

      assert {:ok, %Conference{} = conference} =
               Conferences.update_conference(conference, update_attrs)

      assert conference.date == ~N[2023-06-19 13:33:00]
      assert conference.description == "some updated description"
      assert conference.name == "some updated name"
      assert conference.room == "some updated room"
    end

    test "update_conference/2 with invalid data returns error changeset" do
      conference = conference_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Conferences.update_conference(conference, @invalid_attrs)

      assert conference == Conferences.get_conference!(conference.id)
    end

    test "delete_conference/1 deletes the conference" do
      conference = conference_fixture()
      assert {:ok, %Conference{}} = Conferences.delete_conference(conference)
      assert_raise Ecto.NoResultsError, fn -> Conferences.get_conference!(conference.id) end
    end

    test "change_conference/1 returns a conference changeset" do
      conference = conference_fixture()
      assert %Ecto.Changeset{} = Conferences.change_conference(conference)
    end
  end
end
