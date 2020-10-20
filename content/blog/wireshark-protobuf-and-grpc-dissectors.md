---
title: Wireshark Protobuf and gRPC dissectors
date: 2020-10-20
spelling: cSpell:ignore Huang Qiangxiong
author:
  name: Huang Qiangxiong
---

[Wireshark](https://www.wireshark.org/) is the most famous open source network protocol analyzer, which is widely used in network troubleshooting, analysis, software and communications protocol development, and education. Here is the history of Wireshark Protobuf and gRPC dissectors:

- Wireshark 2.6.0 - adds the initial version of Protobuf and gRPC dissectors.

- Wireshark 3.2.0 - supports dissecting serialized Protobuf data (such as gRPC) more precisely according to *.proto files, and supports dissecting gRPC messages of streaming calls.

- Wireshark 3.3.0 - fixes some bugs about parsing *.proto files and supports some new features about Protobuf dissector.

## Features

The main features about Wireshark Protobuf and gRPC dissectors includes:

- Supports dissecting gRPC messages serialized in Protobuf or JSON format.

- Supports dissecting the gRPC messages of unary, server streaming, client streaming, and bidirectional streaming RPC calls.

- Message and service definition language files (*.proto) can be configured to enable more precise parsing of the serialized data in Protobuf format for protocols such as gRPC.

- Protobuf fields can be dissected as Wireshark fields that allows user to input the full name of a Protobuf field or message in the filter toolbar to search packages containing the field or message.

- You can register your own subdissectors in the 'protobuf_field' dissector table, which is keyed with the full names of the fields, for further parsing Protobuf fields of BYTES or STRING type.

- You can add the mapping record between UDP port and Protobuf message type in the Protobuf protocol preferences dialog, so that the Wireshark can decode the traffic on that UDP port as this Protobuf message.

- You can create your own dissectors to parsing the protocols based on Protobuf over UDP or TCP.

## Examples about using Protobuf and gRPC dissectors

There are some examples to show how to use the Wireshark Protobuf and gRPC dissectors. You can get more details about these examples from [Protobuf wiki](https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf) and [gRPC wiki](https://gitlab.com/wireshark/wireshark/-/wikis/gRPC) pages from Wireshark official website.

### Sample .proto files

These .proto files will be used in the following examples.

The content of `addressbook.proto`:

```protobuf
// This file comes from the official Protobuf example with a little modification.
syntax = "proto3";
package tutorial;
import "google/protobuf/timestamp.proto";

message Person {
  string name = 1;
  int32 id = 2;  // Unique ID number for this person.
  string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    string number = 1;
    PhoneType type = 2;
  }

  repeated PhoneNumber phone = 4;
  google.protobuf.Timestamp last_updated = 5;
  bytes portrait_image = 6;
}

message AddressBook {
  repeated Person people = 1;
}
```

According to the line `'import "google/protobuf/timestamp.proto"'`, the file `addressbook.proto` depends on the official *.proto library of Protobuf.

The content of `person_search_service.proto`:

```protobuf
// A gRPC service that searches for persons based on certain attributes.
syntax = "proto3";
package tutorial;
import "addressbook.proto";

message PersonSearchRequest {
  repeated string name = 1;
  repeated int32 id = 2;
  repeated string phoneNumber = 3;
}

service PersonSearchService {
  rpc Search (PersonSearchRequest) returns (stream Person) {}
}
```
The file `person_search_service.proto` which relies on file `addressbook.proto`.

### Protobuf Search Paths Settings

You can tell Wireshark where to find *.proto files by setting *'Protobuf Search Paths'* at the Protobuf protocol preferences. If both the files `addressbook.proto` and `person_search_service.proto` are in directory `d:/protos/my_proto_files` and the real path of the dependent file `"google/protobuf/timestamp.proto"` is `d:/protos/protobuf-3.4.1/include/google/protobuf/timestamp.proto` (in Protobuf official library directory `d:/protos/protobuf-3.4.1/include`). You should add the `d:/protos/protobuf-3.4.1/include/` and `d:/protos/my_proto_files` paths into *'Protobuf Search Paths'* table and make the *'Load all files'* option of the `'d:/protos/my_proto_files'` record enabled for preloading the message definitions from the `addressbook.proto` file:
![wireshark_protobuf_search_paths](/img/wireshark_protobuf_search_paths.png)
This preferences dialog can be found by menu 'Edit->Preferences->Protocols->ProtoBuf->Protobuf search paths'.

### gRPC Sample Capture files

There are two gRPC sample capture files [grpc_person_search_protobuf_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/f6fcdceb0248669c0b057bd15d45ab6f/grpc_person_search_protobuf_with_image.pcapng) and [grpc_person_search_json_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/88c03db83efb2e3253c88f853d40477b/grpc_person_search_json_with_image.pcapng) on the [SampleCaptures page](https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures) of Wireshark. The difference between the two captures is that the message of former is serialized in Protobuf, and the latter is serialized in JSON.

To decode sample captures as gRPC message, you must decode the traffic on TCP port 50051 and 50052 as HTTP2:
![wireshark_decode_as_dialog](/img/wireshark_decode_as_dialog.png)

#### gRPC Capture serialized in Protobuf

This is a screenshot of the gRPC service request message of [grpc_person_search_protobuf_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/f6fcdceb0248669c0b057bd15d45ab6f/grpc_person_search_protobuf_with_image.pcapng):
![wireshark_grpc_protobuf_search_request](/img/wireshark_grpc_protobuf_search_request.png)
That shows searching for the Person objects of Jason and Lily based on their names. 

Since the `Search` operation is defined as the server streaming RPC mode, the Person objects can be return back to client one after another:
![wireshark_grpc_protobuf_search_response](/img/wireshark_grpc_protobuf_search_response.png)

You may have noticed that the `portrait_image` of bytes type is parsed into a PNG data. It's because we register the PNG dissector in the `"protobuf_field"` dissector table for parsing the value of field `portrait_image` as picture by putting following Lua script `'protobuf_portrait_field.lua'` into the 'plugins' subdirectory of 'Personal configuration' directory:

```lua
do
    local protobuf_field_table = DissectorTable.get("protobuf_field")
    local png_dissector = Dissector.get("png")
    protobuf_field_table:add("tutorial.Person.portrait_image", png_dissector)
end
```

#### gRPC Capture serialized in JSON

Following is a screenshot of [grpc_person_search_json_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/88c03db83efb2e3253c88f853d40477b/grpc_person_search_json_with_image.pcapng), which serializes gRPC message with JSON:
![wireshark_grpc_json_search_response](/img/wireshark_grpc_json_search_response.png)

>Note, if the gRPC message is serialized in JSON, the *'Protobuf Search Paths'* does not need to be configured.

### Protobuf Sample Capture files

#### Built-in Protobuf UDP dissector

You can add a record about UDP port and message type mapping to the *'Protobuf UDP Message Types'* table in Protobuf preferences for parsing packages on the UDP port as this message type:
![wireshark_udp_port_message_type_settings](/img/wireshark_udp_port_message_type_settings.png)
>Note, The field of 'UDP ports' might be a range, for example, "8127,8200-8300,9127".

To test that you can try the sample capture file [protobuf_udp_addressbook_with_image.pcapng](https://gitlab.com/wireshark/editor-wiki/-/wikis/uploads/4dde0c0be2c88ad980a0f42a9f1507cb/protobuf_udp_addressbook_with_image.pcapng) on the [SampleCaptures page](https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures) with Wireshark:
![wireshark_protobuf_udp_with_image](/img/wireshark_protobuf_udp_with_image.png)

Another way to parse Protobuf UDP packets is to write a simple script with Lua to create a dissector for each root message type, that allows you to use "Decode as..." feature on UDP packets. This method will be introduced in the next section.

#### Write your own Protobuf UDP or TCP dissectors

If the root message type of a Protobuf UDP and TCP protocol is the `'tutorial.AddressBook'` in `addressbook.proto`, and the whole payload of an UDP package is a `'tutorial.AddressBook'` message, and each message of the protocol over TCP is a `'tutorial.AddressBook'` message prefixed by 4 bytes length in big-endian ([4bytes length][a message][4bytes length][a message]...), then you can put following file named `'create_protobuf_dissector.lua'` in your 'plugins' subdirectory of 'Personal configuration' directory:
```lua
do
    local protobuf_dissector = Dissector.get("protobuf")

    -- Create protobuf dissector based on UDP or TCP.
    -- The UDP dissector will take the whole tvb as a message.
    -- The TCP dissector will parse tvb as format:
    --         [4bytes length][a message][4bytes length][a message]...
    -- @param name  The name of the new dissector.
    -- @param desc  The description of the new dissector.
    -- @param for_udp  Register the new dissector to UDP table.(Enable 'Decode as')
    -- @param for_tcp  Register the new dissector to TCP table.(Enable 'Decode as')
    -- @param msgtype  Message type. This must be the root message defined in your .proto file.
    local function create_protobuf_dissector(name, desc, for_udp, for_tcp, msgtype)
        local proto = Proto(name, desc)
        local f_length = ProtoField.uint32(name .. ".length", "Length", base.DEC)
        proto.fields = { f_length }

        proto.dissector = function(tvb, pinfo, tree)
            local subtree = tree:add(proto, tvb())
            if for_udp and pinfo.port_type == 3 then -- UDP
                if msgtype ~= nil then
                    pinfo.private["pb_msg_type"] = "message," .. msgtype
                end
                pcall(Dissector.call, protobuf_dissector, tvb, pinfo, subtree)
            elseif for_tcp and pinfo.port_type == 2 then -- TCP
                local offset = 0
                local remaining_len = tvb:len()
                while remaining_len > 0 do
                    if remaining_len < 4 then -- head not enough
                        pinfo.desegment_offset = offset
                        pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
                        return -1
                    end

                    local data_len = tvb(offset, 4):uint()

                    if remaining_len - 4 < data_len then -- data not enough
                        pinfo.desegment_offset = offset
                        pinfo.desegment_len = data_len - (remaining_len - 4)
                        return -1
                    end
                    subtree:add(f_length, tvb(offset, 4))

                    if msgtype ~= nil then
                        pinfo.private["pb_msg_type"] = "message," .. msgtype
                    end
                    pcall(Dissector.call, protobuf_dissector, 
                           tvb(offset + 4, data_len):tvb(), pinfo, subtree)

                    offset = offset + 4 + data_len
                    remaining_len = remaining_len - 4 - data_len
                end
            end
            pinfo.columns.protocol:set(name)
        end

        if for_udp then DissectorTable.get("udp.port"):add(0, proto) end
        if for_tcp then DissectorTable.get("tcp.port"):add(0, proto) end
        return proto
    end

    -- default pure protobuf udp and tcp dissector without message type
    create_protobuf_dissector("protobuf_udp", "Protobuf UDP")
    create_protobuf_dissector("protobuf_tcp", "Protobuf TCP")
    -- add more protobuf dissectors with message types
    create_protobuf_dissector("AddrBook", "Tutorial AddressBook",
                              true, true, "tutorial.AddressBook")
end
```

>Note, You can find the 'Personal configuration' directory from your Wireshark 'About' dialog by menu 'About->Folders->Personal configuration'.

To test the Protobuf TCP dissector, you can open the [protobuf_ tcp_ addressbook.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/b2f61c813d697e3ed22accf728de3122/protobuf_tcp_addressbook.pcapng) on the [SampleCaptures page](https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures) and click the 'Decode As' menu to select the ADDRBOOK protocol (on 18127 TCP port). The 4 bytes length field and the AddressBook message will be dissected like:
![wireshark_protobuf_decode_as_tcp](/img/wireshark_protobuf_decode_as_tcp.png)

You can also apply 'decode as' ADDRBOOK on the UDP packages of the capture file [protobuf_udp_addressbook_with_image.pcapng](https://gitlab.com/wireshark/editor-wiki/-/wikis/uploads/4dde0c0be2c88ad980a0f42a9f1507cb/protobuf_udp_addressbook_with_image.pcapng) mentioned in previous section after removing the mapping record about 8127 UDP port in *'Protobuf UDP Message Types'* table of Protobuf preferences.

If you have a new Protobuf TCP dissector using root message type like 'package.NewMessage', and each message is also prefixed by 4 bytes length field, you can just add following line to 
'create_protobuf_dissector.lua' file:
```lua
    create_protobuf_dissector("NewProtocolName", "New Protocol Name", true, true, "package.NewMessage")
```

## References

- Wireshark gRPC wiki page - https://gitlab.com/wireshark/wireshark/-/wikis/gRPC
- Wireshark gRPC sample captures - https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures#grpc
- Wireshark Protobuf wiki page - https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf
- Wireshark Protobuf sample captures - https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures#protobuf
