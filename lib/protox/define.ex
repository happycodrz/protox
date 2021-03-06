defmodule Protox.Define do
  @moduledoc false
  # Generates structs from message and enumeration definitions.

  defmacro __using__(enums: enums, messages: messages) do
    define(
      enums |> Code.eval_quoted() |> elem(0),
      messages |> Code.eval_quoted() |> elem(0)
    )
  end

  def define(enums, messages) do
    define_enums(enums) ++ define_messages(messages)
  end

  # -- Private

  defp define_enums(enums) do
    for {enum_name, constants} <- enums do
      default_fun = make_enum_default(constants)
      encode_constants_funs = make_encode_enum_constants(constants)
      decode_constants_funs = make_decode_enum_constants(constants)

      module_ast =
        quote do
          unquote(default_fun)

          @spec encode(atom) :: integer | atom
          unquote(encode_constants_funs)
          def encode(x), do: x

          @spec decode(integer) :: atom | integer
          unquote(decode_constants_funs)
          def decode(x), do: x

          @spec constants() :: [{integer, atom}]
          def constants(), do: unquote(constants)
        end

      debug_fun = make_debug_fun(module_ast)

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false
          unquote(module_ast)
          unquote(debug_fun)
        end
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp define_messages(messages) do
    for {msg_name, syntax, fields} <- messages do
      fields = Enum.sort(fields, &(elem(&1, 0) < elem(&2, 0)))
      unknown_fields = make_unknown_fields(:__uf__, fields)
      struct_fields = make_struct_fields(fields, unknown_fields, syntax)
      required_fields = make_required_fields(fields)
      required_fields_typesecs = make_required_fields_typespec(required_fields)
      fields_map = make_fields_map(fields)
      fields_by_name_map = make_fields_by_name_map(fields)
      encoder = Protox.DefineEncoder.define(fields, required_fields, syntax)
      decoder = Protox.DefineDecoder.define(msg_name, fields, required_fields, syntax)
      default_fun = make_default_fun(fields)

      module_ast =
        quote do
          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)

          @spec defs() :: %{
                  required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
                }
          def defs(), do: unquote(fields_map)

          @spec defs_by_name() :: %{
                  required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
                }
          def defs_by_name(), do: unquote(fields_by_name_map)

          @spec required_fields() :: unquote(required_fields_typesecs)
          def required_fields(), do: unquote(required_fields)

          @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
          def unknown_fields(msg), do: msg.unquote(unknown_fields)

          @spec unknown_fields_name() :: unquote(unknown_fields)
          def unknown_fields_name(), do: unquote(unknown_fields)

          @spec clear_unknown_fields(struct) :: struct
          def clear_unknown_fields(msg), do: struct!(msg, [{unknown_fields_name(), []}])

          @spec syntax() :: atom
          def syntax(), do: unquote(syntax)

          unquote(default_fun)
        end

      debug_fun = make_debug_fun(module_ast)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false
          unquote(module_ast)
          unquote(debug_fun)
        end
      end
    end
  end

  defp make_debug_fun(module_ast) do
    if Mix.env() in [:dev, :test] do
      str = Macro.to_string(module_ast)

      quote do
        def __generated_code__() do
          unquote(str)
        end
      end
    else
      quote do
        []
      end
    end
  end

  defp make_default_fun(fields) do
    spec =
      quote do
        @spec default(atom) ::
                {:ok, boolean | integer | String.t() | binary | float} | {:error, atom}
      end

    match_all =
      quote do
        def default(_), do: {:error, :no_such_field}
      end

    ast =
      Enum.map(fields, fn
        {_, _, name, {:default, default}, _} ->
          quote do
            def default(unquote(name)), do: {:ok, unquote(default)}
          end

        {_, _, name, _, _} ->
          quote do
            def default(unquote(name)), do: {:error, :no_default_value}
          end
      end)

    [spec, ast, match_all]
  end

  # Make sure the name chosen for the struct fields that stores the unknow fields
  # of the protobuf message doesn't collide with already existing names.
  defp make_unknown_fields(name, fields) do
    name_in_fields = Enum.find(fields, fn {_, _, n, _, _} -> n == name end)

    if name_in_fields do
      # Append a '_' while there's a collision
      name
      |> Atom.to_string()
      |> (fn x -> x <> "_" end).()
      |> String.to_atom()
      |> make_unknown_fields(fields)
    else
      name
    end
  end

  # -- Enum

  defp make_enum_default(constant_values) do
    # proto2: the first entry is always the default value
    # proto3: the entry with value 0 is the default value, and protoc mandates the first entry
    # to have the value 0
    [{_, default_value} | _] = constant_values

    quote do
      @spec default() :: unquote(default_value)
      def default(), do: unquote(default_value)
    end
  end

  defp make_encode_enum_constants(constant_values) do
    for {value, constant} <- constant_values do
      quote do
        def encode(unquote(constant)), do: unquote(value)
      end
    end
  end

  defp make_decode_enum_constants(constant_values) do
    # Map.new -> unify enum aliases
    for {value, constant} <- Map.new(constant_values) do
      quote do
        def decode(unquote(value)), do: unquote(constant)
      end
    end
  end

  # -- Message

  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, unknown_fields, syntax) do
    struct_fields =
      for {_, _, name, kind, _} <- fields do
        case kind do
          :map -> {name, Macro.escape(%{})}
          {:oneof, parent} -> {parent, nil}
          :packed -> {name, []}
          :unpacked -> {name, []}
          {:default, _} when syntax == :proto2 -> {name, nil}
          {:default, default_value} when syntax == :proto3 -> {name, default_value}
        end
      end ++ [{unknown_fields, []}]

    Enum.uniq(struct_fields)
  end

  # Get the list of fields that are marked as `required`.
  defp make_required_fields(fields) do
    for {_, :required, name, _, _} <- fields, do: name
  end

  defp make_required_fields_typespec([]) do
    quote do: []
  end

  defp make_required_fields_typespec(fields) do
    specs =
      Enum.reduce(
        fields,
        fn field, acc ->
          quote do: unquote(acc) | unquote(field)
        end
      )

    quote do: [unquote(specs)]
  end

  # Generate a map used to store a message's definitions.
  defp make_fields_map(fields) do
    fields
    |> Enum.reduce(%{}, fn {tag, _, name, kind, type}, acc ->
      Map.put(acc, tag, {name, kind, make_type_field(kind, type)})
    end)
    |> Macro.escape()
  end

  defp make_fields_by_name_map(fields) do
    fields
    |> Enum.reduce(%{}, fn {tag, _, name, kind, type}, acc ->
      Map.put(acc, name, {tag, kind, make_type_field(kind, type)})
    end)
    |> Macro.escape()
  end

  defp make_type_field(:map, {key_type, {:message, msg}}), do: {key_type, {:message, msg}}
  defp make_type_field(:map, {key_type, {:enum, enum}}), do: {key_type, {:enum, enum}}
  defp make_type_field(_, {:enum, enum}), do: {:enum, enum}
  defp make_type_field(_, {:message, enum}), do: {:message, enum}
  defp make_type_field(_, ty), do: ty
end
