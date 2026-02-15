defmodule Beamclaw2.Agent do
  @moduledoc """
  Data struct representing an agent's state.

  Agents follow a status lifecycle:
    :initializing → :idle → :running → :completed | :failed | :stopped

  Any status can transition to :stopped (explicit shutdown).
  """

  @type status :: :initializing | :idle | :running | :completed | :failed | :stopped

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          status: status(),
          metadata: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  import Bitwise

  @enforce_keys [:id, :name, :status, :created_at, :updated_at]
  defstruct [:id, :name, :status, :metadata, :created_at, :updated_at]

  @valid_transitions %{
    initializing: [:idle, :failed, :stopped],
    idle: [:running, :stopped],
    running: [:completed, :failed, :stopped],
    completed: [:stopped],
    failed: [:stopped]
  }

  @doc """
  Creates a new Agent struct with a generated UUID and current timestamps.
  """
  @spec new(map()) :: t()
  def new(attrs \\ %{}) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: generate_uuid(),
      name: Map.get(attrs, :name, "unnamed"),
      status: :initializing,
      metadata: Map.get(attrs, :metadata, %{}),
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Checks if a status transition is valid.
  """
  @spec valid_transition?(status(), status()) :: boolean()
  def valid_transition?(from, to) do
    to in Map.get(@valid_transitions, from, [])
  end

  @doc """
  Transitions the agent to a new status if valid.
  """
  @spec transition(t(), status()) :: {:ok, t()} | {:error, :invalid_transition}
  def transition(%__MODULE__{status: current} = agent, new_status) do
    if valid_transition?(current, new_status) do
      {:ok, %{agent | status: new_status, updated_at: DateTime.utc_now()}}
    else
      {:error, :invalid_transition}
    end
  end

  defp generate_uuid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)

    [
      String.pad_leading(Integer.to_string(a, 16), 8, "0"),
      String.pad_leading(Integer.to_string(b, 16), 4, "0"),
      String.pad_leading(Integer.to_string(bor(band(c, 0x0FFF), 0x4000), 16), 4, "0"),
      String.pad_leading(Integer.to_string(bor(band(d, 0x3FFF), 0x8000), 16), 4, "0"),
      String.pad_leading(Integer.to_string(e, 16), 12, "0")
    ]
    |> Enum.join("-")
    |> String.downcase()
  end
end
