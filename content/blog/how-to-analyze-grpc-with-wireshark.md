---
title: How to analyze gRPC with Wireshark
date: 2020-11-27
spelling: cSpell:ignore Huang Qiangxiong
author:
  name: Huang Qiangxiong
  link: https://github.com/huangqiangxiong
---

[Wireshark](https://www.wireshark.org/) is the most famous open source network protocol analyzer, which is widely used in network troubleshooting, analysis, software and communications protocol development, and education. With Wireshark, people can analyze the messages of gRPC protocol that transferred over the wire (network), or learning the binary wire format of these protocols. This tutorial will show you how to configure and use Wireshark gRPC dissector to analyze gRPC with *.proto files. Note that the gRPC dissector actually relies on the Protocol Buffers (Protobuf) dissector, and some functions (including setting *.proto files paths) are accomplished through the Protobuf dissector. Wireshark started to support parsing gRPC (and Protobuf) in version 2.6.0, and some new features (including supporting *.proto* files) have been added in later versions. You can refer to section [History of Wireshark gRPC and Protobuf Dissectors](#history-of-wireshark-grpc-and-protobuf-dissectors) for details. Wireshark 3.4.0 is the latest stable version, is also the version we used to introduce examples later.

## Features of Wireshark Protobuf and gRPC dissectors

The main features about Wireshark Protobuf and gRPC dissectors includes:

- Supports dissecting gRPC messages serialized in Protobuf or JSON format.

- Supports dissecting the gRPC messages of unary, server streaming, client streaming, and bidirectional streaming RPC calls.

- Message and service definition language files (*.proto) can be configured to enable more precise parsing of the serialized data in Protobuf format for protocols such as gRPC.

- Protobuf fields can be dissected as Wireshark fields that allows user to input the full name of a Protobuf field or message in the filter toolbar to search packages containing the field or message.

- You can register your own subdissectors in the 'protobuf_field' dissector table, which is keyed with the full names of the fields, for further parsing Protobuf fields of BYTES or STRING type.

- You can add the mapping record between UDP port and Protobuf message type in the Protobuf protocol preferences dialog, so that the Wireshark can decode the traffic on that UDP port as this Protobuf message.

- You can create your own dissectors to parsing the protocols based on Protobuf over UDP or TCP.

## Capture gRPC traffic

There are many ways to capture the network traffic of a gRPC conversation:

- Windows: Use Wireshark to capture traffic from many different network media types, including Ethernet, Wireless LAN, and more.

- Linux/UNIX: Use Tcpdump.

Please refer to [Wireshark User's Guide](https://www.wireshark.org/docs/wsug_html_chunked/) for how to capture network packets files that can be recognized by Wireshark.

Note that now only the capture files that sending gRPC messages in plaintext mode can be parsed by Wireshark. For example, you have to setup a gRPC client channel using plaintext mode in java like:
```java
NettyChannelBuilder.forAddress(host, port).negotiationType(NegotiationType.PLAINTEXT).build();
```

In theory, as long as the session secret keys of TLS can be exported in format of Wireshark [key log file](https://gitlab.com/wireshark/wireshark/-/wikis/tls) from client or server side, the gRPC traffic encrypted in TLS can also be parsed by Wireshark. But as I know, gRPC stub libraries do not support exporting session secret keys of TLS now or not support directly. Hope this feature might be supported in the future.

## Examples about using Protobuf and gRPC dissectors

There are some examples to show how to use the Wireshark Protobuf and gRPC dissectors. You can get more details about these examples from [Wireshark Protobuf wiki page](https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf) and [Wireshark gRPC wiki page](https://gitlab.com/wireshark/wireshark/-/wikis/gRPC) pages from Wireshark official website.

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

According to the line `'import "google/protobuf/timestamp.proto"'`, the file `addressbook.proto` depends on one of [*Protocol Bufferes Well-Known Types*](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf).

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

## Read more about Protobuf Dissector

Since Protobuf is not only used by gRPC, user can parse their own Protobuf based protocols with Wireshark Protobuf dissector. But this is not a gRPC related topic. If you are interested in how to write your own Protobuf UDP or TCP dissectors, you can refer to [Wireshark Protobuf wiki page](https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf).

## History of Wireshark gRPC and Protobuf Dissectors

- Wireshark 2.6.0 - adds the initial version of Protobuf and gRPC dissectors. (Note that this version does not support *.proto files)
- Wireshark 3.2.0 - supports dissecting serialized Protobuf data (such as gRPC) more precisely according to *.proto files, and supports dissecting gRPC messages of streaming calls.
- Wireshark 3.3.0 - fixes some bugs about parsing *.proto files and supports some new features about Protobuf dissector. (You can search message in capture file by the value of Protobuf field since this version)
- Wireshark 3.4.0 - supports displaying the Protobuf well known type Timestamp as locale date-time string.

## References

- Wireshark gRPC wiki page - https://gitlab.com/wireshark/wireshark/-/wikis/gRPC
- Wireshark gRPC sample captures - https://gitlab.com/wireshark/wireshark/-/wikis/SampleCaptures#grpc
- Wireshark Protobuf wiki page - https://gitlab.com/wireshark/wireshark/-/wikis/Protobuf

