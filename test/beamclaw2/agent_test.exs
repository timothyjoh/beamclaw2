defmodule Beamclaw2.AgentTest do
  use ExUnit.Case, async: true

  alias Beamclaw2.Agent

  describe "new/1" do
    test "creates agent with defaults" do
      agent = Agent.new()
      assert agent.name == "unnamed"
      assert agent.status == :initializing
      assert agent.metadata == %{}
      assert is_binary(agent.id)
      assert String.length(agent.id) == 36
      assert %DateTime{} = agent.created_at
      assert %DateTime{} = agent.updated_at
    end

    test "creates agent with custom name and metadata" do
      agent = Agent.new(%{name: "my-agent", metadata: %{role: "worker"}})
      assert agent.name == "my-agent"
      assert agent.metadata == %{role: "worker"}
    end
  end

  describe "valid_transition?/2" do
    test "initializing can go to idle, failed, stopped" do
      assert Agent.valid_transition?(:initializing, :idle)
      assert Agent.valid_transition?(:initializing, :failed)
      assert Agent.valid_transition?(:initializing, :stopped)
      refute Agent.valid_transition?(:initializing, :running)
      refute Agent.valid_transition?(:initializing, :completed)
    end

    test "idle can go to running, stopped" do
      assert Agent.valid_transition?(:idle, :running)
      assert Agent.valid_transition?(:idle, :stopped)
      refute Agent.valid_transition?(:idle, :completed)
    end

    test "running can go to completed, failed, stopped" do
      assert Agent.valid_transition?(:running, :completed)
      assert Agent.valid_transition?(:running, :failed)
      assert Agent.valid_transition?(:running, :stopped)
      refute Agent.valid_transition?(:running, :idle)
    end

    test "terminal states can only go to stopped" do
      assert Agent.valid_transition?(:completed, :stopped)
      assert Agent.valid_transition?(:failed, :stopped)
      refute Agent.valid_transition?(:completed, :running)
      refute Agent.valid_transition?(:failed, :running)
    end

    test "stopped is terminal" do
      refute Agent.valid_transition?(:stopped, :idle)
      refute Agent.valid_transition?(:stopped, :running)
    end
  end

  describe "transition/2" do
    test "valid transition updates status and timestamp" do
      agent = Agent.new()
      Process.sleep(1)
      {:ok, updated} = Agent.transition(agent, :idle)
      assert updated.status == :idle
      assert DateTime.compare(updated.updated_at, agent.updated_at) in [:gt, :eq]
    end

    test "invalid transition returns error" do
      agent = Agent.new()
      assert {:error, :invalid_transition} = Agent.transition(agent, :completed)
    end
  end
end
