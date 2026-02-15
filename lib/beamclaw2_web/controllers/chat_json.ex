defmodule Beamclaw2Web.ChatJSON do
  @moduledoc """
  JSON serialization for chat completion responses.
  """

  def completion(data) do
    %{
      id: data.id,
      model: data.model,
      content: data.content,
      stop_reason: data.stop_reason,
      usage: %{
        input_tokens: data.usage.input_tokens,
        output_tokens: data.usage.output_tokens
      }
    }
  end

  def chunk(data) do
    %{
      type: data.type,
      content: data.content
    }
  end
end
