defmodule Beamclaw2.ApplicationTest do
  use ExUnit.Case

  describe "application" do
    test "supervisor is running" do
      assert Process.whereis(Beamclaw2.Supervisor) != nil
    end

    test "endpoint is running" do
      children =
        Supervisor.which_children(Beamclaw2.Supervisor)
        |> Enum.map(&elem(&1, 0))

      assert Beamclaw2Web.Endpoint in children
    end

    test "pubsub is running" do
      children =
        Supervisor.which_children(Beamclaw2.Supervisor)
        |> Enum.map(&elem(&1, 0))

      assert Phoenix.PubSub.Supervisor in children
    end
  end
end
