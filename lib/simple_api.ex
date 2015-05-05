if Mix.env == :test do
  defmodule Simple.Api do
    @moduledoc """
    This api describes very simple get/put storage api.
    And should be a very small example of how to use it.
    """
    use Apix
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

    ## Attributes

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

    ## Attributes

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
end
