defmodule Defs do

  use Protox.BuildMessage, messages: [
    {
      Sub,
      [
        {1 , :a, :normal, :int32},
        {2 , :b, :normal, :string},
        {6 , :c, :normal, :int64},
        {7 , :d, :normal, :uint32},
        {8 , :e, :normal, :uint64},
        {9 , :f, :normal, :sint64},
        {13, :g, {:repeated, :packed}, :fixed64},
        {14, :h, {:repeated, :packed}, :sfixed32},
        {15, :i, {:repeated, :packed}, :double},
        {16, :j, {:repeated, :unpacked}, :int32},
        {17, :k, :normal, :fixed32},
        {18, :l, :normal, :sfixed64},
        {19, :m, :normal, :bytes},
        {10001, :z, :normal, :sint32},
      ]
    },
    {
      Msg,
      [
        {1 , :d, :normal, {:enum, [{0, :FOO}, {1, :BAR}]}},
        {2 , :e, :normal, :bool},
        {3 , :f, :normal, {:message, Sub}},
        {4 , :g, {:repeated, :packed}, :int32},
        {5 , :h, :normal, :double},
        {6 , :i, {:repeated, :packed}, :float},
        {7 , :j, {:repeated, :unpacked}, {:message, Sub}},
        {8 , :k, :map, {:int32, :string}},
        {9 , :l, :map, {:string, :double}},
        {10, :n, {:oneof, :m}, :string},
        {11, :o, {:oneof, :m}, {:message, Sub}},
      ]
    },
    {
      Upper,
      [
        {1, :msg, :normal, {:message, Msg}},
        {2, :msg_map, :map, {:string, {:message, Msg}}},
      ]
    }
  ]

end

#-------------------------------------------------------------------------------------------------#