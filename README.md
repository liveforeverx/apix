Apix
====

Simple convention and DSL for transformation of elixir functions to a documented and ready for validation API.

Example of usage (very simple get/put API):

```elixir
defmodule Simple.Api do
  @moduledoc """
  This api describes very simple get/put storage api.
  And should be a very small example of how to use it.
  """
  use Apix
  @name "SimpleStore"
  @tech_name "store"
  api "Get", :get
  api "Put", :put

  def ensure_started() do
    case Process.whereis(:simple) do
      nil ->
        {:ok, pid} = Agent.start_link(fn -> %{} end)
        Process.register(pid, :simple)
      _ ->
        :ok
    end
  end

  @doc """
  Get value for a defined key

  ## Parameters

    * `:key` - string, must be sent
    * `:default` - string, optional, defines default, if nothing found to be returned

  ## Results

  """
  def get(%{key: key} = args) do
    ensure_started()
    %{result: Agent.get(:simple, &Map.get(&1, key, args[:default]))}
  end

  @doc """
  Put a value for the key

  ## Parameters

    * `:key` - string, describes key, on which it will be saved
    * `:value` - string, describes value

  ## Results

  """
  def put(%{key: key, value: value} = _args) do
    ensure_started()
    Agent.update(:simple, &Map.put(&1, key, value))
    %{result: true}
  end
end
```

Now, it is possible to get information to your API:

```elixir
iex> Apix.spec(Simple.Api, :methods)
["Get", "Put"]
iex> Apix.spec(Simple.Api, :method, "Put")
%{arguments: [key: %{description: "describes key, on which it will be saved", optional: false, type: "string"},
              value: %{description: "describes value", optional: false, type: "string"}],
  doc: "Put a value for the key"}
iex> Apix.spec(Simple.Api, :name)
"SimpleStore"
iex> Apix.spec(Simple.Api, :doc)
"This api describes very simple get/put storage api.\nAnd should be a very small example of how to use it.\n"
```

There are some word in documetation, which will be identified, for example:
`## Parameters`, starting the attributes section.

Each attribute should have the same format: "* `key` - type, description" or
"* `key` - type, optional, description". Type should be of type, which your validator
supports. Apix may support JSON validation in the future.

For more information, use Apix documentation. All examples are actually tested with `doctest`.
