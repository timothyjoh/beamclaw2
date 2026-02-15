defmodule Beamclaw2.LLM.ChatCompletions do
  @moduledoc """
  Public API for chat completions. Facade over LLM providers.
  Similar to AgentManager — clean public interface for the web layer.
  """

  alias Beamclaw2.LLM.Providers.Anthropic

  @doc """
  Perform a synchronous chat completion.

  ## Options
  - `:model` - Model name (default: provider default)
  - `:max_tokens` - Maximum tokens to generate
  - `:temperature` - Sampling temperature
  - `:system` - System prompt
  - `:provider` - Provider module (default: Anthropic)
  """
  @spec complete([map()], map()) :: {:ok, map()} | {:error, atom()} | {:error, atom(), map()}
  def complete(messages, opts \\ %{}) do
    provider = Map.get(opts, :provider, default_provider())
    provider.chat(messages, Map.delete(opts, :provider))
  end

  @doc """
  Perform a streaming chat completion. Returns parsed chunks.
  """
  @spec stream([map()], map()) :: {:ok, [map()]} | {:error, atom()} | {:error, atom(), map()}
  def stream(messages, opts \\ %{}) do
    provider = Map.get(opts, :provider, default_provider())
    provider.stream(messages, Map.delete(opts, :provider))
  end

  defp default_provider do
    Application.get_env(:beamclaw2, :llm_provider, Anthropic)
  end
end
