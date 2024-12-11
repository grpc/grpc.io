---
title: Protocol Buffer Compiler Installation
linkTitle: Protoc Installation
description: How to install the protocol buffer compiler.
protoc-version: 25.1
toc_hide: true
---

While not mandatory, gRPC applications often leverage [Protocol Buffers][pb] for
service definitions and data serialization. Most of the example code from this
site uses [version 3 of the protocol buffer language (proto3)][proto3].

The protocol buffer compiler, `protoc`, is used to compile `.proto` files, which
contain service and message definitions. Choose one of the methods given below
to install `protoc`.

### Install using a package manager

You can install the protocol compiler, `protoc`, with a package manager under
Linux or macOS using the following commands.

{{% alert title="Warning" color="warning" %}}
  **Check the version of `protoc`** (as indicated below) after installation to
  ensure that it is sufficiently recent. The versions of `protoc` installed by
  some package managers can be quite dated.

  Installing from pre-compiled binaries, as indicated in the [next
  section](#binary-install), is the best way to ensure that you're using the
  latest release of `protoc`.
{{% /alert %}}

- Linux, using `apt` or `apt-get`, for example:

  ```sh
  apt install -y protobuf-compiler
  protoc --version  # Ensure compiler version is 3+
  ```

- MacOS, using [Homebrew][]:

  ```sh
  brew install protobuf
  protoc --version  # Ensure compiler version is 3+
  ```
- Windows, using [Winget][]

  ```sh
  > winget install protobuf
  > protoc --version # Ensure compiler version is 3+

<a name="binary-install"></a>

### Install pre-compiled binaries (any OS)

To install the [latest release][] of the protocol compiler from pre-compiled
binaries, follow these instructions:

 1. Manually download from [github.com/google/protobuf/releases][] the zip file
    corresponding to your operating system and computer architecture
    (`protoc-<version>-<os>-<arch>.zip`), or fetch the file using commands such
    as the following:

    ```sh
    PB_REL="https://github.com/protocolbuffers/protobuf/releases"
    curl -LO $PB_REL/download/v{{< param protoc-version >}}/protoc-{{< param protoc-version >}}-linux-x86_64.zip
    ```

 2. Unzip the file under `$HOME/.local` or a directory of your choice. For
    example:

    ```sh
    unzip protoc-{{< param protoc-version >}}-linux-x86_64.zip -d $HOME/.local
    ```

 3. Update your environment's path variable to include the path to the
    `protoc` executable. For example:

    ```sh
    export PATH="$PATH:$HOME/.local/bin"
    ```

### Other installation options

If you'd like to build the protocol compiler from sources, or access older
versions of the pre-compiled binaries, see [Download Protocol
Buffers][download].

[download]: https://protobuf.dev/downloads
[github.com/google/protobuf/releases]: https://github.com/google/protobuf/releases
[Homebrew]: https://brew.sh
[latest release]: https://protobuf.dev/downloads#release-packages
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://protobuf.dev/programming-guides/proto3
[winget]: https://learn.microsoft.com/en-us/windows/package-manager/winget/
