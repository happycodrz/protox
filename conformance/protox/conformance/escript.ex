defmodule Protox.Conformance.Escript do
  @moduledoc false

  # An escript that will be called by the protobuf conformance test runner
  # It reads a conformance test request on its standard input and outputs
  # the test results on the standard output.

  def main(_args) do
    run()
  end

  defp run() do
    :io.setopts(:standard_io, encoding: :latin1)

    :ok = File.mkdir_p("conformance_report")

    "./conformance_report/report_#{System.system_time()}.txt"
    |> File.open!([:write])
    |> loop()
  end

  defp loop(log_file) do
    IO.binwrite(log_file, "\n---------\n")

    case IO.binread(:stdio, 4) do
      :eof ->
        IO.binwrite(log_file, "EOF\n")
        :ok

      {:error, reason} ->
        IO.binwrite(log_file, "Error: #{inspect(reason)}\n")
        {:error, reason}

      <<len::unsigned-little-32>> ->
        :stdio
        |> IO.binread(len)
        |> dump_data(log_file)
        |> Conformance.ConformanceRequest.decode()
        |> handle_request(log_file)
        |> make_message_bytes()
        |> output(log_file)

        loop(log_file)
    end
  end

  defp handle_request(
         req = %Conformance.ConformanceRequest{
           requested_output_format: :PROTOBUF,
           payload: {:protobuf_payload, _}
         },
         log_file
       ) do
    IO.binwrite(log_file, "Will parse protobuf\n")

    IO.binwrite(log_file, "#{inspect(req)}\n")

    {:protobuf_payload, payload} = req.payload

    proto_type =
      case req.message_type do
        "protobuf_test_messages.proto3.TestAllTypesProto3" ->
          ProtobufTestMessages.Proto3.TestAllTypesProto3

        "protobuf_test_messages.proto2.TestAllTypesProto2" ->
          ProtobufTestMessages.Proto2.TestAllTypesProto2

        "conformance.FailureSet" ->
          Conformance.FailureSet

        "" ->
          ProtobufTestMessages.Proto3.TestAllTypesProto3
      end

    try do
      msg = proto_type.decode(payload)
      IO.binwrite(log_file, "Parse: success.\n")
      IO.binwrite(log_file, "Message: #{inspect(msg, limit: :infinity)}\n")
      encoded_payload = msg.__struct__.encode(msg)
      IO.binwrite(log_file, "Encoded payload: #{inspect(encoded_payload, limit: :infinity)}\n")
      %Conformance.ConformanceResponse{result: {:protobuf_payload, encoded_payload}}
    rescue
      e ->
        IO.binwrite(log_file, "Parse error: #{inspect(e)}\n")

        %Conformance.ConformanceResponse{
          result: {:parse_error, "Parse error: #{inspect(e)}"}
        }
    end
  end

  # All JSON and TEXT related tests are skipped.
  defp handle_request(req, log_file) do
    skip_reason =
      case {req.requested_output_format, req.payload} do
        {:UNSPECIFIED, _} ->
          "unspecified input"

        {:JSON, _} ->
          "json input"

        {:PROTOBUF, {:json_payload, _}} ->
          "json output"

        {:PROTOBUF, nil} ->
          "unset payload"

        {:PROTOBUF, {:text_payload, _}} ->
          "text output"

        {:TEXT_FORMAT, _} ->
          "text output"
      end

    IO.binwrite(log_file, "SKIPPED\n")
    IO.binwrite(log_file, "Reason: #{inspect(skip_reason)}\n")
    IO.binwrite(log_file, "#{inspect(req)}\n")
    %Conformance.ConformanceResponse{result: {:skipped, "SKIPPED"}}
  end

  defp dump_data(data, log_file) do
    IO.binwrite(log_file, "Received #{inspect(data, limit: :infinity)}\n")
    data
  end

  defp output(data, log_file) do
    IO.binwrite(log_file, "Will write #{byte_size(data)} bytes\n")
    IO.binwrite(:stdio, data)
  end

  defp make_message_bytes(msg) do
    data = msg.__struct__.encode(msg)
    <<byte_size(data)::unsigned-little-32, data::binary>>
  end
end
