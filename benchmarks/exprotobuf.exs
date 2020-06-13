defmodule Exprotobuf do
  use Protobuf, from: "./benchmarks/benchmarks.proto"
end

defmodule Protox.Benchmarks.Run do
  def decode({mod, bytes}), do: namespace(mod).decode(bytes)
  def encode(msg), do: Protobuf.Serializable.serialize(msg)

  def decode_name(), do: "decode_exprotobuf"
  def decode_file_name(), do: "decode_exprotobuf.benchee"

  def encode_name(), do: "encode_exprotobuf"
  def encode_file_name(), do: "encode_exprotobuf.benchee"

  defp namespace(mod), do: Module.safe_concat([Exprotobuf, mod])
end
