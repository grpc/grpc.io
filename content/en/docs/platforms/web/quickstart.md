---
title: Quick start
description: This guide gets you started with gRPC-Web with a simple working example.
weight: 10
---

### Prerequisites

- Docker and `docker-compose` supporting [Docker Compose file version 3][dcfv3].
  For installation instructions see [Install Compose][install].

  [dcfv3]: https://docs.docker.com/compose/compose-file/compose-versioning
  [install]: https://docs.docker.com/compose/install/#install-compose

### Get the example code

The example code is part of the [grpc-web][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone https://github.com/grpc/grpc-web
    ```

 2. Change to the repo's root directory:

    ```sh
    cd grpc-web
    ```

### Run an Echo example from your browser!

From the `grpc-web` directory:

 1. Fetch required packages and tools:

    ```sh
    docker-compose pull prereqs node-server envoy commonjs-client
    ```

    {{% alert title="Note" color="info" %}}
Getting the following warning? You can ignore it for the purpose of running the
example app:

```nocode
WARNING: Some service image(s) must be built from source
```
    {{% /alert %}}

 2. Launch services as background processes:

    ```sh
    docker-compose up -d node-server envoy commonjs-client
    ```

 3. From your browser:

    - Visit
    [localhost:8081/echotest.html](http://localhost:8081/echotest.html).
    - Enter a message, like "Hello", in the text-input box.
    - Press the **Send** button.

    You'll see your message echoed by the server below the input box.

Congratulations! You've just run a client-server application with gRPC.

Once you are done, shutdown the services that you launched earlier by running
the following command:

```sh
docker-compose down
```

### What is happening?

This example app has three key components:

 1. `node-server` is a standard gRPC server, implemented in Node. This server
    listens at port `:9090`, and implements the app's business logic (echoing
    client messages).
 2. `envoy` is the Envoy proxy. It listens at `:8080` and forwards the browser's
    gRPC-Web requests to port `:9090`.
 3. `commonjs-client`: this component generates the client stub class using the
    `protoc-gen-grpc-web` protoc plugin, compiles all the JS dependencies using
    `webpack`, and hosts the static content (`echotest.html` and `dist/main.js`)
    at port `:8081` using a simple web server. User messages entered from the
    webpage are sent to the Envoy proxy as gRPC-web requests.

### What's next

- Work through the [Basics tutorial](../basics/).

[download]: https://github.com/grpc/grpc-web/archive/master.zip
[grpc-web]: https://github.com/grpc/grpc-web
