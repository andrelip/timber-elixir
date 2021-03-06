defmodule Timber.Events.CustomEvent do
  @moduledoc ~S"""
  The `CustomEvent` represents events that aren't covered elsewhere.

  The defined structure of this data can be found in the log event JSON schema:
  https://github.com/timberio/log-event-json-schema

  Custom events can be used to structure information about events that are central
  to your line of business like receiving credit card payments, saving a draft of a post,
  or changing a user's password.

  ## Fields

    * `type` - (atom, required) This is the type of your event. It should be something unique
      and unchanging. It will be used to identify this event. Example: `:my_event`.
    * `data` - (map, optional) A map of data. This can be anything that can be JSON encoded.
      Example: `%{key: "value"}`.

  ## Special `data` fields

  Timber treats these fields as special. We'll display them on the interface where relevant,
  create graphs, etc.:

    * `:time_ms` (float, optional) - Represents the execution time in fractional milliseconds.
      Example: `45.6`

  ## Example

  There are 2 ways to log custom events:

  1. Log a map (simplest)

    ```elixir
    event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    Logger.info("Payment rejected", event: %{payment_rejected: event_data})
    ```

    The `:payment_rejected` key is the event `type`, and of course the value is the `data`.

  2. Log a struct (advanced)

    Defining structs for your events creates a contract around your data structure.
    We recommend this approach when you have downstream consumers that will be affected
    by data structure changes.

    ```elixir
    def PaymentRejectedEvent do
      use Timber.Events.CustomEvent, type: :payment_rejected

      @enforce_keys [:customer_id, :amount, :currency]
      defstruct [:customer_id, :amount, :currency]

      def message(%__MODULE__{customer_id: customer_id}) do
        "Payment rejected for #{customer_id}"
      end
    end

    event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    message = PaymentRejectedEvent.message(event)
    Logger.info(message, event: event)
    ```

  """

  @type t :: %__MODULE__{
    type: atom(),
    data: map() | nil
  }

  defmacro __using__(opts) do
    quote do
      defimpl Timber.Eventable, for: __MODULE__ do
        def to_event(event) do
          type = Keyword.get(unquote(opts), :type, __MODULE__)
          data = Map.from_struct(event)
          %Timber.Events.CustomEvent{type: type, data: data}
        end
      end
    end
  end

  @enforce_keys [:type]
  defstruct [
    :data,
    :type
  ]
end
