defmodule Beamclaw2.Logger.JSONFormatterTest do
  use ExUnit.Case, async: true

  alias Beamclaw2.Logger.JSONFormatter

  @timestamp {{2026, 2, 15}, {18, 30, 45, 123}}

  describe "format/4" do
    test "produces valid JSON" do
      output =
        JSONFormatter.format(:info, "hello", @timestamp, module: MyApp, function: "run/1")
        |> IO.iodata_to_binary()

      assert {:ok, decoded} = Jason.decode(output)
      assert is_map(decoded)
    end

    test "includes required fields" do
      output =
        JSONFormatter.format(:info, "test message", @timestamp,
          module: MyApp,
          function: "run/1",
          line: 42,
          pid: self()
        )
        |> IO.iodata_to_binary()

      {:ok, decoded} = Jason.decode(output)

      assert decoded["level"] == "info"
      assert decoded["message"] == "test message"
      assert decoded["timestamp"] == "2026-02-15T18:30:45.123Z"
      assert decoded["module"] == "Elixir.MyApp"
      assert decoded["function"] == "run/1"
      assert decoded["line"] == 42
      assert is_binary(decoded["pid"])
    end

    test "handles all log levels" do
      for level <- [:debug, :info, :warning, :error] do
        output =
          JSONFormatter.format(level, "msg", @timestamp, [])
          |> IO.iodata_to_binary()

        {:ok, decoded} = Jason.decode(output)
        assert decoded["level"] == Atom.to_string(level)
      end
    end

    test "omits nil metadata fields" do
      output =
        JSONFormatter.format(:info, "msg", @timestamp, [])
        |> IO.iodata_to_binary()

      {:ok, decoded} = Jason.decode(output)
      refute Map.has_key?(decoded, "module")
      refute Map.has_key?(decoded, "function")
      refute Map.has_key?(decoded, "request_id")
    end

    test "includes request_id when present" do
      output =
        JSONFormatter.format(:info, "msg", @timestamp, request_id: "abc-123")
        |> IO.iodata_to_binary()

      {:ok, decoded} = Jason.decode(output)
      assert decoded["request_id"] == "abc-123"
    end

    test "ends with newline" do
      output =
        JSONFormatter.format(:info, "msg", @timestamp, [])
        |> IO.iodata_to_binary()

      assert String.ends_with?(output, "\n")
    end

    test "pads single-digit month/day/hour/minute/second" do
      timestamp = {{2026, 1, 5}, {3, 7, 9, 1}}

      output =
        JSONFormatter.format(:info, "msg", timestamp, [])
        |> IO.iodata_to_binary()

      {:ok, decoded} = Jason.decode(output)
      assert decoded["timestamp"] == "2026-01-05T03:07:09.001Z"
    end

    test "handles iodata messages" do
      output =
        JSONFormatter.format(:info, ["hello", " ", "world"], @timestamp, [])
        |> IO.iodata_to_binary()

      {:ok, decoded} = Jason.decode(output)
      assert decoded["message"] == "hello world"
    end
  end
end
