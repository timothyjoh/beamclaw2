defmodule Beamclaw2.AgentServerTest do
  use ExUnit.Case, async: false

  alias Beamclaw2.AgentServer

  setup do
    # Each test gets a unique agent
    {:ok, pid} = Beamclaw2.AgentSupervisor.start_agent(%{name: "test-agent"})
    {:ok, agent} = GenServer.call(pid, :get_state)
    %{pid: pid, agent: agent}
  end

  describe "start_link/1" do
    test "starts and registers an agent process", %{agent: agent} do
      assert agent.name == "test-agent"
      assert agent.status == :initializing
      assert [{_pid, _}] = Registry.lookup(Beamclaw2.AgentRegistry, agent.id)
    end
  end

  describe "get_state/1" do
    test "returns agent state by id", %{agent: agent} do
      assert {:ok, ^agent} = AgentServer.get_state(agent.id)
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = AgentServer.get_state("nonexistent")
    end
  end

  describe "update_status/2" do
    test "valid transition updates status", %{agent: agent} do
      {:ok, updated} = AgentServer.update_status(agent.id, :idle)
      assert updated.status == :idle
    end

    test "invalid transition returns error", %{agent: agent} do
      assert {:error, :invalid_transition} = AgentServer.update_status(agent.id, :completed)
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = AgentServer.update_status("nonexistent", :idle)
    end
  end
end
