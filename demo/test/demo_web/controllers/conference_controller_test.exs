defmodule DemoWeb.ConferenceControllerTest do
  use DemoWeb.ConnCase

  import Demo.ConferencesFixtures

  @create_attrs %{
    date: ~N[2023-06-18 13:33:00],
    description: "some description",
    name: "some name",
    room: "some room"
  }
  @update_attrs %{
    date: ~N[2023-06-19 13:33:00],
    description: "some updated description",
    name: "some updated name",
    room: "some updated room"
  }
  @invalid_attrs %{date: nil, description: nil, name: nil, room: nil}

  describe "index" do
    test "lists all conferences", %{conn: conn} do
      conn = get(conn, ~p"/conferences")
      assert html_response(conn, 200) =~ "Listing Conferences"
    end
  end

  describe "new conference" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/conferences/new")
      assert html_response(conn, 200) =~ "New Conference"
    end
  end

  describe "create conference" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/conferences", conference: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/conferences/#{id}"

      conn = get(conn, ~p"/conferences/#{id}")
      assert html_response(conn, 200) =~ "Conference #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/conferences", conference: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Conference"
    end
  end

  describe "edit conference" do
    setup [:create_conference]

    test "renders form for editing chosen conference", %{conn: conn, conference: conference} do
      conn = get(conn, ~p"/conferences/#{conference}/edit")
      assert html_response(conn, 200) =~ "Edit Conference"
    end
  end

  describe "update conference" do
    setup [:create_conference]

    test "redirects when data is valid", %{conn: conn, conference: conference} do
      conn = put(conn, ~p"/conferences/#{conference}", conference: @update_attrs)
      assert redirected_to(conn) == ~p"/conferences/#{conference}"

      conn = get(conn, ~p"/conferences/#{conference}")
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, conference: conference} do
      conn = put(conn, ~p"/conferences/#{conference}", conference: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Conference"
    end
  end

  describe "delete conference" do
    setup [:create_conference]

    test "deletes chosen conference", %{conn: conn, conference: conference} do
      conn = delete(conn, ~p"/conferences/#{conference}")
      assert redirected_to(conn) == ~p"/conferences"

      assert_error_sent 404, fn ->
        get(conn, ~p"/conferences/#{conference}")
      end
    end
  end

  defp create_conference(_) do
    conference = conference_fixture()
    %{conference: conference}
  end
end
