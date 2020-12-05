---
draft: true
spelling: cSpell:ignore addressbook Huang pcapng Qiangxiong subdissectors tcpdump Wireshark
title: Analyzing gRPC messages using Wireshark
date: 2020-12-04
author:
  name: Huang Qiangxiong
  link: https://github.com/huangqiangxiong
---

[Wireshark](https://www.wireshark.org) is an open source network protocol
analyzer, which can be used for protocol development, network troubleshooting,
and education. Wireshark lets you analyze gRPC messages that are transferred
over the wire (network), and learn about the binary wire format of these
messages.

In this post you'll learn how to configure and use the Wireshark [gRPC
dissector][] and the [Protocol Buffers (Protobuf) dissector][], which are
protocol-specific components that allow you to analyze gRPC messages with
Wireshark.

## Features

The main features of the gRPC and Protobuf dissectors are the following:

- Support dissecting (decoding) gRPC messages serialized in the
  protocol buffer wire format or as JSON

- Support dissecting gRPC messages of unary, server streaming, client streaming,
  and bidirectional streaming RPC calls

- Enhanced dissection of serialized protocol buffers data by allowing
  you do the following:
  - Load relevant `.proto` files
  - Register your own subdissectors for protocol buffer fields of type `byte` or
    `string`

## Capturing gRPC traffic

This post focuses on the analysis of captured gRPC messages. To learn how to
store network traffic in _capture files_, see the [Capturing Live Network
Data][] section of the [Wireshark User’s Guide][].

{{<note>}}
  Currently, only **plain text** gRPC messages can be parsed by Wireshark. While
  [Wireshark supports TLS dissection][], it requires per-session secret keys. As
  of the time of writing, gRPC libraries do not support the exporting of such
  keys.

  [Wireshark supports TLS dissection]: https://gitlab.com/wireshark/wireshark/-/wikis/tls
{{</note>}}

## Examples

There are some examples to show how to use the Wireshark Protobuf and gRPC
dissectors. You can get more details about these examples from [Wireshark
Protobuf wiki page](https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf) and
[Wireshark gRPC wiki page](https://gitlab.com/wireshark/wireshark/-/wikis/gRPC)
on Wireshark official website.

### Sample .proto files

These `.proto` files will be used in the following examples.

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

According to the line `'import "google/protobuf/timestamp.proto"'`, the file
`addressbook.proto` depends on one of [Protocol Buffers Well-Known
Types](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf).

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

The file `person_search_service.proto` relies on file `addressbook.proto`.

### Protobuf Search Paths Settings

You can tell Wireshark where to find *.proto files by setting *'Protobuf Search
Paths'* at the Protobuf protocol preferences. If both the files
`addressbook.proto` and `person_search_service.proto` are in directory
`d:/protos/my_proto_files` and the real path of the dependent file
`"google/protobuf/timestamp.proto"` is
`d:/protos/protobuf-3.4.1/include/google/protobuf/timestamp.proto` (in Protobuf
official library directory `d:/protos/protobuf-3.4.1/include`). You should add
the `d:/protos/protobuf-3.4.1/include/` and `d:/protos/my_proto_files` paths
into *'Protobuf Search Paths'* table and make the *'Load all files'* option of
the `'d:/protos/my_proto_files'` record enabled for preloading the message
definitions from the `addressbook.proto` file:
![wireshark_protobuf_search_paths](/img/wireshark_protobuf_search_paths.png)
This preferences dialog can be found by menu
'Edit->Preferences->Protocols->ProtoBuf->Protobuf search paths'.

### gRPC Sample Capture files

There are two gRPC sample capture files
[grpc_person_search_protobuf_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/f6fcdceb0248669c0b057bd15d45ab6f/grpc_person_search_protobuf_with_image.pcapng)
and
[grpc_person_search_json_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/88c03db83efb2e3253c88f853d40477b/grpc_person_search_json_with_image.pcapng)
on the [SampleCaptures
page](https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures) of
Wireshark. The difference between the two captures is that the message of former
is serialized in Protobuf, and the latter is serialized in JSON.

To decode sample captures as gRPC message, you must decode the traffic on TCP
port 50051 and 50052 as HTTP2:
![wireshark_decode_as_dialog](/img/wireshark_decode_as_dialog.png)

This is a screenshot of the gRPC service request message of
[grpc_person_search_protobuf_with_image.pcapng](https://gitlab.com/wireshark/wireshark/-/wikis/uploads/f6fcdceb0248669c0b057bd15d45ab6f/grpc_person_search_protobuf_with_image.pcapng):
![wireshark_grpc_protobuf_search_request](/img/wireshark_grpc_protobuf_search_request.png)
That shows searching for the Person objects of Jason and Lily based on their
names.

Since the `Search` operation is defined as the server streaming RPC mode, the
Person objects can be return back to client one after another:
![wireshark_grpc_protobuf_search_response](/img/wireshark_grpc_protobuf_search_response.png)

You may have noticed that the `portrait_image` of bytes type is parsed as a
PNG data. It's because we register the PNG dissector in the `"protobuf_field"`
dissector table for parsing the value of field `portrait_image` as picture by
putting following Lua script `'protobuf_portrait_field.lua'` into the 'plugins'
subdirectory of 'Personal configuration' directory:

```lua
do
    local protobuf_field_table = DissectorTable.get("protobuf_field")
    local png_dissector = Dissector.get("png")
    protobuf_field_table:add("tutorial.Person.portrait_image", png_dissector)
end
```

## History of gRPC and Protocol Buffers support

Here is a brief annotated list of Wireshark versions as they relate to the
support of gRPC and Protocol Buffers:

- v2.6.0: first release of gRPC and Protobuf dissectors, without
  support for `.proto` files or streaming RPCs.
- v3.2.0: improved dissection of serialized protocol buffers data based on
  `.proto` files, and support of streaming RPCs.
- v3.3.0: improved and enhanced `.proto` file support, such as capture-file
  search on protocol buffer field values.
- v3.4.0: Protocol Buffers [Timestamp][] time is displayed as locale date-time
  string.

## Learn more

- [Wireshark User’s Guide][]
- [gRPC dissector][]
- [Protocol Buffers (Protobuf) dissector][]

[Capturing Live Network Data]: https://www.wireshark.org/docs/wsug_html_chunked/ChapterCapture.html
[gRPC dissector]: https://gitlab.com/wireshark/wireshark/-/wikis/gRPC
[Protocol Buffers (Protobuf) dissector]: https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf
[Timestamp]: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp
[Wireshark User’s Guide]: https://www.wireshark.org/docs/wsug_html_chunked/
