defmodule Beamclaw2Web.AgentControllerTest do
  use Beamclaw2Web.ConnCase

  alias Beamclaw2.AgentManager

  setup do
    # Clean up agents after each test by stopping all
    on_exit(fn ->
      AgentManager.list_agents()
      |> Enum.each(fn agent -> AgentManager.stop_agent(agent.id) end)
    end)

    :ok
  end

  describe "POST /api/agents" do
    test "creates agent with valid name", %{conn: conn} do
      conn = post(conn, ~p"/api/agents", %{"name" => "test-agent"})

      assert %{"data" => %{"id" => id, "name" => "test-agent", "status" => "initializing"}} =
               json_response(conn, 201)

      assert is_binary(id)
    end

    test "creates agent with metadata", %{conn: conn} do
      conn =
        post(conn, ~p"/api/agents", %{
          "name" => "test-agent",
          "metadata" => %{"model" => "gpt-4"}
        })

      assert %{"data" => %{"metadata" => %{"model" => "gpt-4"}}} = json_response(conn, 201)
    end

    test "returns 422 when name is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/agents", %{})
      assert %{"error" => %{"message" => "name is required"}} = json_response(conn, 422)
    end

    test "returns 422 when name is empty string", %{conn: conn} do
      conn = post(conn, ~p"/api/agents", %{"name" => ""})
      assert %{"error" => %{"message" => "name is required"}} = json_response(conn, 422)
    end
  end

  describe "GET /api/agents" do
    test "returns empty list when no agents", %{conn: conn} do
      conn = get(conn, ~p"/api/agents")
      assert %{"data" => []} = json_response(conn, 200)
    end

    test "returns list of agents", %{conn: conn} do
      {:ok, _} = AgentManager.create_agent(%{name: "agent-1"})
      {:ok, _} = AgentManager.create_agent(%{name: "agent-2"})

      conn = get(conn, ~p"/api/agents")
      assert %{"data" => agents} = json_response(conn, 200)
      assert length(agents) == 2
    end
  end

  describe "GET /api/agents/:id" do
    test "returns agent by id", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = get(conn, ~p"/api/agents/#{agent.id}")

      assert %{"data" => %{"id" => id, "name" => "my-agent"}} = json_response(conn, 200)
      assert id == agent.id
    end

    test "returns 404 for non-existent agent", %{conn: conn} do
      conn = get(conn, ~p"/api/agents/nonexistent-id")
      assert %{"error" => %{"message" => "Not found"}} = json_response(conn, 404)
    end
  end

  describe "PATCH /api/agents/:id" do
    test "updates agent status", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = patch(conn, ~p"/api/agents/#{agent.id}", %{"status" => "idle"})
      assert %{"data" => %{"status" => "idle"}} = json_response(conn, 200)
    end

    test "returns 422 for invalid status transition", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = patch(conn, ~p"/api/agents/#{agent.id}", %{"status" => "completed"})
      assert %{"error" => %{"message" => "Invalid status transition"}} = json_response(conn, 422)
    end

    test "returns 422 for unknown status", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = patch(conn, ~p"/api/agents/#{agent.id}", %{"status" => "bogus"})
      assert %{"error" => %{"message" => "invalid status: bogus"}} = json_response(conn, 422)
    end

    test "returns 422 when status is missing", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = patch(conn, ~p"/api/agents/#{agent.id}", %{})
      assert %{"error" => %{"message" => "status is required"}} = json_response(conn, 422)
    end

    test "returns 404 for non-existent agent", %{conn: conn} do
      conn = patch(conn, ~p"/api/agents/nonexistent", %{"status" => "idle"})
      assert %{"error" => %{"message" => "Not found"}} = json_response(conn, 404)
    end
  end

  describe "DELETE /api/agents/:id" do
    test "stops agent and returns 204", %{conn: conn} do
      {:ok, agent} = AgentManager.create_agent(%{name: "my-agent"})

      conn = delete(conn, ~p"/api/agents/#{agent.id}")
      assert response(conn, 204)

      # Agent should no longer exist
      assert {:error, :not_found} = AgentManager.get_agent(agent.id)
    end

    test "returns 404 for non-existent agent", %{conn: conn} do
      conn = delete(conn, ~p"/api/agents/nonexistent")
      assert %{"error" => %{"message" => "Not found"}} = json_response(conn, 404)
    end
  end
end
