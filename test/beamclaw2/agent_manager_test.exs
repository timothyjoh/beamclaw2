defmodule Beamclaw2.AgentManagerTest do
  use ExUnit.Case, async: false

  alias Beamclaw2.AgentManager

  describe "create_agent/1" do
    test "creates a new agent" do
      {:ok, agent} = AgentManager.create_agent(%{name: "creator-test"})
      assert agent.name == "creator-test"
      assert agent.status == :initializing
      assert is_binary(agent.id)
    end
  end

  describe "get_agent/1" do
    test "retrieves existing agent" do
      {:ok, agent} = AgentManager.create_agent(%{name: "getter-test"})
      {:ok, fetched} = AgentManager.get_agent(agent.id)
      assert fetched.id == agent.id
      assert fetched.name == "getter-test"
    end

    test "returns not_found for missing agent" do
      assert {:error, :not_found} = AgentManager.get_agent("nope")
    end
  end

  describe "list_agents/0" do
    test "lists all running agents" do
      {:ok, a1} = AgentManager.create_agent(%{name: "list-1"})
      {:ok, a2} = AgentManager.create_agent(%{name: "list-2"})
      agents = AgentManager.list_agents()
      ids = Enum.map(agents, & &1.id)
      assert a1.id in ids
      assert a2.id in ids
    end
  end

  describe "update_status/2" do
    test "transitions agent status" do
      {:ok, agent} = AgentManager.create_agent(%{name: "status-test"})
      {:ok, updated} = AgentManager.update_status(agent.id, :idle)
      assert updated.status == :idle
    end
  end

  describe "stop_agent/1" do
    test "stops a running agent" do
      {:ok, agent} = AgentManager.create_agent(%{name: "stop-test"})
      assert :ok = AgentManager.stop_agent(agent.id)
      assert {:error, :not_found} = AgentManager.get_agent(agent.id)
    end

    test "returns error for missing agent" do
      assert {:error, :not_found} = AgentManager.stop_agent("nope")
    end
  end

  describe "integration" do
    test "full lifecycle: create → get → update → list → stop" do
      {:ok, agent} = AgentManager.create_agent(%{name: "lifecycle"})
      assert agent.status == :initializing

      {:ok, _} = AgentManager.update_status(agent.id, :idle)
      {:ok, _} = AgentManager.update_status(agent.id, :running)
      {:ok, updated} = AgentManager.update_status(agent.id, :completed)
      assert updated.status == :completed

      agents = AgentManager.list_agents()
      assert Enum.any?(agents, &(&1.id == agent.id))

      :ok = AgentManager.stop_agent(agent.id)
      assert {:error, :not_found} = AgentManager.get_agent(agent.id)
    end
  end
end
