defmodule Defs do
  use Protox.Define,
    enums: [
      {
        E,
        [
          {0, :FOO},
          {1, :BAZ},
          {1, :BAR},
          {-1, :NEG}
        ]
      },
      {
        F,
        [
          {1, :ONE},
          {2, :TWO}
        ]
      }
    ],
    messages: [
      {
        Protobuf2,
        :proto2,
        [
          {1, :optional, :a, {:default, 0}, :uint64},
          {25, :optional, :s, {:default, :TWO}, {:enum, F}},
          {26, :optional, :t, {:default, :ONE}, {:enum, F}}
        ]
      },
      {
        Sub,
        :proto3,
        [
          # tag     label    name     kind           type
          {1, :optional, :a, {:default, 0}, :int32},
          {2, :optional, :b, {:default, ""}, :string},
          {6, :optional, :c, {:default, 0}, :int64},
          {7, :optional, :d, {:default, 0}, :uint32},
          {8, :optional, :e, {:default, 0}, :uint64},
          {9, :optional, :f, {:default, 0}, :sint64},
          {13, :repeated, :g, :packed, :fixed64},
          {14, :repeated, :h, :packed, :sfixed32},
          {15, :repeated, :i, :packed, :double},
          {16, :repeated, :j, :unpacked, :int32},
          {17, :optional, :k, {:default, 0}, :fixed32},
          {18, :optional, :l, {:default, 0}, :sfixed64},
          {19, :optional, :m, {:default, <<>>}, :bytes},
          {20, :repeated, :n, :packed, :bool},
          {21, :repeated, :o, :packed, {:enum, E}},
          {22, :repeated, :p, :unpacked, :bool},
          {23, :repeated, :q, :unpacked, {:enum, E}},
          {24, :optional, :r, {:default, :FOO}, {:enum, E}},
          {27, :repeated, :u, :packed, :uint32},
          {28, :repeated, :w, :packed, :sint32},
          {29, :repeated, :x, :packed, :int64},
          {30, :repeated, :y, :packed, :uint64},
          {10_001, :optional, :z, {:default, 0}, :sint32},
          {10_002, :optional, :zz, {:default, 0}, :sint64},
          {12_345, nil, :map1, :map, {:sfixed64, :bytes}},
          {12_346, nil, :map2, :map, {:sfixed64, :bytes}}
        ]
      },
      {
        Msg,
        :proto3,
        [
          {27, :repeated, :msg_a, :packed, :sint64},
          {28, :repeated, :msg_b, :packed, :fixed32},
          {29, :repeated, :msg_c, :packed, :sfixed64},
          {1, :optional, :msg_d, {:default, :FOO}, {:enum, E}},
          {2, :optional, :msg_e, {:default, false}, :bool},
          {3, :optional, :msg_f, {:default, nil}, {:message, Sub}},
          {4, :repeated, :msg_g, :packed, :int32},
          {5, :optional, :msg_h, {:default, 0.0}, :double},
          {6, :repeated, :msg_i, :packed, :float},
          {7, :repeated, :msg_j, :unpacked, {:message, Sub}},
          {8, nil, :msg_k, :map, {:int32, :string}},
          {9, nil, :msg_l, :map, {:string, :double}},
          {10, :optional, :msg_n, {:oneof, :msg_m}, :string},
          {11, :optional, :msg_o, {:oneof, :msg_m}, {:message, Sub}},
          {12, nil, :msg_p, :map, {:int32, {:enum, E}}},
          {13, :optional, :msg_q, {:default, nil}, {:message, Protobuf2}},
          {118, :optional, :msg_oneof_double, {:oneof, :msg_oneof_field}, :double}
        ]
      },
      {
        Upper,
        :proto3,
        [
          {1, :optional, :msg, {:default, nil}, {:message, Msg}},
          {2, nil, :msg_map, :map, {:string, {:message, Msg}}},
          {3, :optional, :empty, {:default, nil}, {:message, Empty}},
          {4, :optional, :req, {:default, nil}, {:message, Required}}
        ]
      },
      {
        Empty,
        :proto3,
        []
      },
      {
        Required,
        :proto2,
        [
          {1, :required, :a, {:default, 0}, :int32},
          {2, :optional, :b, {:default, 0}, :int32}
        ]
      },
      {
        NoNameClash,
        :proto3,
        [
          {1, :optional, :__uf__, {:default, 0}, :int32}
        ]
      },
      {
        NestedMessage,
        :proto3,
        [
          {1, :none, :a, {:default, 0}, :int32},
          {2, :none, :corecursive, {:default, nil}, {:message, TestAllTypesProto3}}
        ]
      },
      {
        TestAllTypesProto3,
        :proto3,
        [
          {112, :none, :oneof_nested_message, {:oneof, :oneof_field}, {:message, NestedMessage}}
        ]
      },
      {
        FloatPrecision,
        :proto3,
        [
          {1, :optional, :a, {:default, 0.0}, :double},
          {2, :optional, :b, {:default, 0.0}, :float}
        ]
      }
    ]
end
