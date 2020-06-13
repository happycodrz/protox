Code.compile_file("./benchmarks/benchmarks.pb.exs")

defmodule Protox.Benchmarks.Run do
  def decode({mod, bytes}), do: namespace(mod).decode(bytes)
  def encode(msg), do: msg.__struct__.encode(msg)

  def decode_name(), do: "decode_protobuf"
  def decode_file_name(), do: "decode_protobuf.benchee"

  def encode_name(), do: "encode_protobuf"
  def encode_file_name(), do: "encode_protobuf.benchee"

  defp namespace(mod), do: Module.safe_concat([mod])
end
