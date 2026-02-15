defmodule Beamclaw2.LLM.Provider do
  @moduledoc """
  Behaviour defining the contract for LLM providers.

  Any LLM backend (Anthropic, OpenAI, etc.) implements this behaviour
  to provide chat completion capabilities.
  """

  @type message :: %{role: String.t(), content: String.t()}

  @type options :: %{
          optional(:model) => String.t(),
          optional(:max_tokens) => pos_integer(),
          optional(:temperature) => float(),
          optional(:system) => String.t()
        }

  @type completion :: %{
          id: String.t(),
          model: String.t(),
          content: String.t(),
          stop_reason: String.t() | nil,
          usage: %{input_tokens: non_neg_integer(), output_tokens: non_neg_integer()}
        }

  @type chunk :: %{
          type: :content_delta | :message_start | :message_stop | :error,
          content: String.t() | nil,
          metadata: map()
        }

  @type error :: {:error, :api_error, map()} | {:error, :network_error, term()}

  @doc "Perform a synchronous chat completion."
  @callback chat(messages :: [message()], opts :: options()) ::
              {:ok, completion()} | error()

  @doc "Perform a streaming chat completion. Returns a list of chunks."
  @callback stream(messages :: [message()], opts :: options()) ::
              {:ok, [chunk()]} | error()
end
