Our example is a simple route mapping application that lets clients get
information about features on their route, create a summary of their route, and
exchange route information such as traffic updates with the server and other
clients.

With gRPC we can define our service once in a `.proto` file and generate clients
and servers in any of gRPC's supported languages, which in turn can be run in
environments ranging from servers inside a large data center to your own tablet —
all the complexity of communication between different languages and environments is
handled for you by gRPC. We also get all the advantages of working with protocol
buffers, including efficient serialization, a simple IDL, and easy interface
updating.