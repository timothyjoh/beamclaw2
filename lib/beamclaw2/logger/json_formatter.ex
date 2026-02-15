defmodule Beamclaw2.Logger.JSONFormatter do
  @moduledoc """
  JSON formatter for Elixir Logger.

  Formats log events as single-line JSON objects with structured metadata
  including timestamp, level, message, module, function, and line.
  """

  @doc """
  Formats a log event as a JSON string.

  Used as `{Beamclaw2.Logger.JSONFormatter, :format}` in Logger config.
  """
  @spec format(Logger.level(), Logger.message(), Logger.Formatter.time(), keyword()) ::
          IO.chardata()
  def format(level, message, timestamp, metadata) do
    %{
      timestamp: format_timestamp(timestamp),
      level: level,
      message: IO.chardata_to_string(message),
      module: metadata[:module],
      function: metadata[:function],
      line: metadata[:line],
      pid: inspect(metadata[:pid]),
      request_id: metadata[:request_id]
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> Jason.encode_to_iodata!()
    |> then(&[&1, "\n"])
  rescue
    _ ->
      "#{format_timestamp(timestamp)} [#{level}] #{message}\n"
  end

  defp format_timestamp({date, {hour, minute, second, millisecond}}) do
    {year, month, day} = date

    [
      Integer.to_string(year),
      "-",
      pad2(month),
      "-",
      pad2(day),
      "T",
      pad2(hour),
      ":",
      pad2(minute),
      ":",
      pad2(second),
      ".",
      pad3(millisecond),
      "Z"
    ]
    |> IO.iodata_to_binary()
  end

  defp pad2(int) when int < 10, do: ["0", Integer.to_string(int)]
  defp pad2(int), do: Integer.to_string(int)

  defp pad3(int) when int < 10, do: ["00", Integer.to_string(int)]
  defp pad3(int) when int < 100, do: ["0", Integer.to_string(int)]
  defp pad3(int), do: Integer.to_string(int)
end
