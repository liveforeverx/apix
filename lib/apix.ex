defmodule Apix do
  @moduledoc ~S"""
  Apix allows use native elixir documentation format for documenting APIs.

  ## Example

      iex> defmodule Test.Api do
      ...>   use Apix
      ...>   @name "Test"
      ...>   @tech_name "test"
      ...>   api "Test", :foo
      ...>   @moduledoc "Example api"
      ...>   @doc "Example function"
      ...>   def foo(_), do: :bar
      ...> end
      iex> Apix.spec(Test.Api, :methods)
      ["Test"]
      iex> Apix.apply(Test.Api, "Test", %{})
      :bar

  For more introspection rules, see `spec/1`, `spec/2`, `spec/3` functions.

  There are some word in documetation, which will be identified, for example:
  `## Attributes`, starting the attributes section.

  Each attribute should have the same format: "* `key` - type, description" or
  "* `key` - type, optional, description". Type should be of type, which your validator
  supports.
  """
  @doc_match {{:doc, {:'$1', :'$2'}}, :_, :def, :_, :'$3'}
  defmacro __using__(_opts) do
    quote do
      import Apix, only: :macros
      @apix_apis []
      @before_compile Apix
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    Module.get_attribute(module, :moduledoc) || raise ArgumentError, message: "There must be a module documentation for a module #{io_module(module)}"
    name      = Module.get_attribute(module, :name)      || raise ArgumentError, message: "There must be a `@name` attribute for a module #{io_module(module)}"
    tech_name = Module.get_attribute(module, :tech_name) || raise ArgumentError, message: "There must be a `@tech_name` attribute for a module #{io_module(module)}"
    docs = :elixir_module.data_table(module) |> :ets.match(@doc_match) |> Enum.map(fn([a, b, c]) -> {{a, b}, c} end)
    apis = Module.get_attribute(module, :apix_apis) |> Enum.reverse
    method_specs = method_specs(apis, docs, env)
    quote do
      def __apix__(), do: unquote(tech_name)
      def __apix__(:name), do: unquote(name)
      def __apix__(:methods), do: unquote(Enum.map(apis, &elem(&1, 0)))
      unquote(method_specs)
    end
  end

  @doc """
  This macro, defines the binding between symbolic method name and exported elixir function.
  And defines, which function should be exported as API method.
  """
  defmacro api(method, function, args \\ []) do
    quote bind_quoted: binding() do
      @apix_apis [{method, function, args} | @apix_apis]
    end
  end

  defp method_specs(apis, docs, env) do
    apix_methods = for {method, function, args} <- apis do
      {_, doc} = List.keyfind(docs, {function, length(args) + 1}, 0) || raise ArgumentError, message: "There must be a documentation for a function #{io_module(env.module)}.#{function}/1"
      quote do
        def __apix__(:method, unquote(method)), do: unquote(process_doc(doc) |> Macro.escape)
      end
    end
    applies = for {method, function, args} <- apis do
      quote do
        def __apix__(:apply, unquote(method), args), do: unquote(function)(args, unquote_splicing(args))
      end
    end
    quote do
      unquote(apix_methods)
      unquote(applies)
    end
  end

  defp io_module(module) do
    case to_string(module) do
      "Elixir." <> string -> string
      string -> string
    end
  end

  defp process_doc(doc) do
    String.split(doc, "\n") |> process_doc(:initial, [], %{doc: nil, arguments: []})
  end

  defp process_doc([], state, _acc, result) when state in [:wait, :initial],
    do: result
  defp process_doc(["" | next], :initial, acc, result),
    do: process_doc(next, :wait, [], %{result | doc: Enum.reverse(acc) |> Enum.join("\n")})
  defp process_doc([string | next], :initial, acc, result),
    do: process_doc(next, :initial, [string | acc], result)
  defp process_doc([string | next], :wait, _acc, result) do
    case String.strip(string) do
      "## Attributes" ->
        process_doc(next, :arguments, [], result)
      _ ->
        process_doc(next, :wait, [], result)
    end
  end

  defp process_doc([], :arguments, acc, result) do
    %{result | arguments: Enum.reverse(acc)}
  end
  defp process_doc([string | next], :arguments, acc, result) do
    case String.strip(string) do
      "*" <> value ->
        [_, key, other_parts] = String.split(value, "`", parts: 3)
        process_doc(next, :arguments, [argument(key, other_parts) | acc], result)
      _ ->
        case acc do
          [] -> process_doc(next, :arguments, acc, result)
          _  -> %{result | arguments: Enum.reverse(acc)}
        end
    end
  end

  defp argument(key, " - " <> other_parts) do
    [type | next] = String.split(other_parts, ",")
    key = :"#{key |> String.strip(?:)}"
    case next do
      [may_be_optional, next | rest] ->
        {optional, new_rest} = case String.strip(may_be_optional) do
          "optional" -> {true, [next | rest]}
          _ -> {false, [may_be_optional, next | rest]}
        end
        {key, %{type: type, optional: optional, description: Enum.join(new_rest, ",") |> String.strip}}
      rest ->
        {key, %{type: type, optional: false, description: Enum.join(rest, ",") |> String.strip}}
    end
  end

  @doc ~S"""
  Get api description of a module.

  ## Example
      iex> Apix.spec(Simple.Api)
      "store"
  """
  def spec(module), do: module.__apix__

  @doc ~S"""
  Get specification of a module and defined methods in it.

  ## Example

      iex> Apix.spec(Simple.Api, :name)
      "SimpleStore"
      iex> Apix.spec(Simple.Api, :doc)
      "This api describes very simple get/put storage api.\nAnd should be a very small example of how to use it.\n"
      iex> Apix.spec(Simple.Api, :methods)
      ["Get", "Put"]
  """
  def spec(module, :doc), do: Code.get_docs(module, :moduledoc) |> elem(1)
  def spec(module, key) when key in [:name, :methods], do: module.__apix__(key)

  @doc ~S"""
  Get specification of a method in module and parameters in it.

  ## Example

      iex> Apix.spec(Simple.Api, :method, "Put")
      %{arguments: [key: %{description: "describes key, on which it will be saved", optional: false, type: "string"},
                  value: %{description: "describes value", optional: false, type: "string"}],
        doc: "Put a value for the key"}
  """
  def spec(module, :method, method), do: module.__apix__(:method, method)

  @doc ~S"""
  Apply method on arguments

  ## Example

      iex> Apix.apply(Simple.Api, "Put", %{key: "foo", value: "bar"})
      %{result: true}
      iex> Apix.apply(Simple.Api, "Get", %{key: "foo"})
      %{result: "bar"}
  """
  def apply(module, method, args), do: module.__apix__(:apply, method, args)
end
