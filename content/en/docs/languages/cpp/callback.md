---
title: Asynchronous Callback API Tutorial
linkTitle: Asynchronous Callback API Tutorial
weight: 60
spelling: cSpell:ignore classgrpc Impl's
---

This tutorial shows you how to write a simple server and client in C++ using
gRPC's asynchronous callback APIs. The example used in this tutorial follows the
[RouteGuide example](https://github.com/grpc/grpc/tree/{{< param grpc_vers.core >}}/examples/cpp/route_guide).

## Overview

gRPC C++ offers two kinds of APIs: sync APIs and async APIs. More specifically,
we have two kinds of async APIs: the old one is completion-queue based; the new
one is callback-based, which is easier to use. In this tutorial, we will focus
on the callback-based async APIs (callback APIs for short). You will learn how
to use the callback APIs to implement the server and the client for the
following kinds of RPCs:

*   Unary RPC
*   Server-side streaming RPC
*   Client-side streaming RPC
*   Bidirectional streaming RPC

## Example Code

In this tutorial, we are going to create a route guiding application. The
clients can get information about features on their route, create a summary of
their route, and exchange route information such as traffic updates with the
server and other clients.

Below is the service interface defined in Protocol Buffers.

```protobuf
// Interface exported by the server.
service RouteGuide {
  // A simple RPC.
  //
  // Obtains the feature at a given position.
  //
  // A feature with an empty name is returned if there's no feature at the given
  // position.
  rpc GetFeature(Point) returns (Feature) {}

  // A server-to-client streaming RPC.
  //
  // Obtains the Features available within the given Rectangle.  Results are
  // streamed rather than returned at once (e.g. in a response message with a
  // repeated field), as the rectangle may cover a large area and contain a
  // huge number of features.
  rpc ListFeatures(Rectangle) returns (stream Feature) {}

  // A client-to-server streaming RPC.
  //
  // Accepts a stream of Points on a route being traversed, returning a
  // RouteSummary when traversal is completed.
  rpc RecordRoute(stream Point) returns (RouteSummary) {}

  // A Bidirectional streaming RPC.
  //
  // Accepts a stream of RouteNotes sent while a route is being traversed,
  // while receiving other RouteNotes (e.g. from other users).
  rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
}
```

The same example is also implemented using the *sync* APIs. If you are
interested, you can compare the two implementations.

## Service to Implement

Since we want to implement the service using the callback APIs, the service
interface we should implement is `RouteGuide::CallbackService`.

```c++
class RouteGuideImpl final : public RouteGuide::CallbackService {
  ...
};
```

We will implement all the four RPCs in this service in the `Server` subsections
of the following sections.

## Unary RPC

Let's begin with the simplest RPC: `GetFeature`, which is a unary RPC. By
`GetFeature`, the client sends a `Point` to the server, and then the server
returns the `Feature` of that `Point` to the client.

### Server

The implementation of this RPC is quite simple and straightforward.

```c++
  grpc::ServerUnaryReactor* GetFeature(CallbackServerContext* context,
                                       const Point* point,
                                       Feature* feature) override {
    feature->set_name(GetFeatureName(*point, feature_list_));
    feature->mutable_location()->CopyFrom(*point);
    auto* reactor = context->DefaultReactor();
    reactor->Finish(Status::OK);
    return reactor;
  }
```

After setting the output fields of `Feature`, we return the final status via the
`ServerUnaryReactor`.

### Custom Unary Reactor

The above example uses the Default Reactor. We could also use a custom reactor
here if we want to handle specific actions such as RPC cancellation or run an
action asynchronously when the RPC is done. In the below example we add logs for
both actions.

```c++
  grpc::ServerUnaryReactor* GetFeature(grpc::CallbackServerContext* context,
                                       const Point* point,
                                       Feature* feature) override {
    class Reactor : public grpc::ServerUnaryReactor {
     public:
      Reactor(const Point& point, const std::vector<Feature>& feature_list,
              Feature* feature) {
        feature->set_name(GetFeatureName(point, feature_list));
        *feature->mutable_location() = point;
        Finish(grpc::Status::OK);
      }

     private:
      void OnDone() override {
        LOG(INFO) << "RPC Completed";
        delete this;
      }

      void OnCancel() override { LOG(ERROR) << "RPC Cancelled"; }
    };
    return new Reactor(*point, feature_list_, feature);
  }
```

For `ServerUnaryReactor`, we need to override `OnDone()`, and optionally
`OnCancel()`.

> **NOTE** The callback methods (e.g., `OnDone()`) are supposed to return
> quickly. Never perform blocking work (e.g., waiting for an event) in such
> callbacks.

The `ServerUnaryReactor`'s constructor is called when `GetFeature()` constructs
and provides the reactor in response to the started RPC. It collects the request
`Point`, the response `Feature` and the `feature_list`. It then gets the
response `Feature` from the `Point` and adds it to the feature_list as well. To
finish the RPC we call `Finish(Status::OK)`.

`OnDone()` reacts to the RPC completion. We will do the final cleanup in
`OnDone()` and log the end of the RPC.

`OnCancel()` reacts to the cancellation of the RPC. Here, we log the occurrence
of a cancellation in this method.

### Client

NOTE: For simplicity, we will not discuss how to create a channel and a stub in
this tutorial. Please refer to [Basics tutorial](/docs/languages/cpp/basics/)
for that.

To start a `GetFeature` RPC, besides a `ClientContext`, a request (i.e.,
`Point`), and a response (i.e., `Feature`), the client also needs to pass a
callback (i.e., `std::function<void(::grpc::Status)>`) to
`stub_->async()->GetFeature()`. The callback will be invoked after the server
has fulfilled the request and the RPC is finished.

```c++
  bool GetOneFeature(const Point& point, Feature* feature) {
    ClientContext context;
    bool result;
    std::mutex mu;
    std::condition_variable cv;
    bool done = false;
    stub_->async()->GetFeature(
        &context, &point, feature,
        [&result, &mu, &cv, &done, feature, this](Status status) {
          bool ret;
          if (!status.ok()) {
            std::cout << "GetFeature rpc failed." << std::endl;
            ret = false;
          } else if (!feature->has_location()) {
            std::cout << "Server returns incomplete feature." << std::endl;
            ret = false;
          } else if (feature->name().empty()) {
            std::cout << "Found no feature at "
                      << feature->location().latitude() / kCoordFactor_ << ", "
                      << feature->location().longitude() / kCoordFactor_
                      << std::endl;
            ret = true;
          } else {
            std::cout << "Found feature called " << feature->name() << " at "
                      << feature->location().latitude() / kCoordFactor_ << ", "
                      << feature->location().longitude() / kCoordFactor_
                      << std::endl;
            ret = true;
          }
          std::lock_guard<std::mutex> lock(mu);
          result = ret;
          done = true;
          cv.notify_one();
        });
    std::unique_lock<std::mutex> lock(mu);
    cv.wait(lock, [&done] { return done; });
    return result;
  }
```

A callback can do various follow-up work for a unary RPC. For example, the
callback in the above snippet checks the status and the returned feature, frees
the heap-allocated objects for this call, and finally notifies that the RPC is
done.

For simplicity, the example shows the same function waiting on the notification
for the RPC completion, but that's not necessary.

## Server-side streaming RPC

Now let's look at a more complex RPC - `ListFeatures`. `ListFeatures` is a
server-side streaming RPC. The client sends a `Rectangle` to the server, and the
server will return a sequence of `Feature`s to the client, each of which is sent
in a separate message.

### Server

For any streaming RPC, including the server-side streaming RPC, the RPC
handler's interface is similar. The handler does not have any input parameters;
the return type is some kind of server reactor, which handles all the business
logic for one RPC.

Below is the handler interface of `ListFeatures`.

```c++
  grpc::ServerWriteReactor<Feature>* ListFeatures(
      CallbackServerContext* context,
      const routeguide::Rectangle* rectangle);
```

Because `ListFeatures` is a server-streaming RPC, the return type should be
`ServerWriteReactor`. `ServerWriteReactor` has two template parameters:
`Rectangle` is the type of the request from the client; `Feature` is the type of
each response message from the server.

The complexity of handling an RPC is delegated to the `ServerWriteReactor`.
Below is how we implement the `ServerWriteReactor` to handle a `ListFeatures`
RPC.

```c++
  grpc::ServerWriteReactor<Feature>* ListFeatures(
      CallbackServerContext* context,
      const routeguide::Rectangle* rectangle) override {
    class Lister : public grpc::ServerWriteReactor<Feature> {
     public:
      Lister(const routeguide::Rectangle* rectangle,
             const std::vector<Feature>* feature_list)
          : left_((std::min)(rectangle->lo().longitude(),
                             rectangle->hi().longitude())),
            right_((std::max)(rectangle->lo().longitude(),
                              rectangle->hi().longitude())),
            top_((std::max)(rectangle->lo().latitude(),
                            rectangle->hi().latitude())),
            bottom_((std::min)(rectangle->lo().latitude(),
                               rectangle->hi().latitude())),
            feature_list_(feature_list),
            next_feature_(feature_list_->begin()) {
        NextWrite();
      }

      void OnWriteDone(bool ok) override {
        if (!ok) {
          Finish(Status(grpc::StatusCode::UNKNOWN, "Unexpected Failure"));
        }
        NextWrite();
      }

      void OnDone() override {
        LOG(INFO) << "RPC Completed";
        delete this;
      }

      void OnCancel() override { LOG(ERROR) << "RPC Cancelled"; }

     private:
      void NextWrite() {
        while (next_feature_ != feature_list_->end()) {
          const Feature& f = *next_feature_;
          next_feature_++;
          if (f.location().longitude() >= left_ &&
              f.location().longitude() <= right_ &&
              f.location().latitude() >= bottom_ &&
              f.location().latitude() <= top_) {
            StartWrite(&f);
            return;
          }
        }
        // Didn't write anything, all is done.
        Finish(Status::OK);
      }
      const long left_;
      const long right_;
      const long top_;
      const long bottom_;
      const std::vector<Feature>* feature_list_;
      std::vector<Feature>::const_iterator next_feature_;
    };
    return new Lister(rectangle, &feature_list_);
  }
```

Different reactors have different callback methods. We need to override the
methods we are interested in to implement our RPC. For `ListFeatures`, we need
to override `OnWriteDone()`, `OnDone()` and optionally `OnCancel`.

The `ServerWriteReactor`'s constructor is called when `ListFeatures()`
constructs and provides the reactor in response to the started RPC. It collects
all the `Feature`s within `rectangle` into `features_to_send_`, and starts
sending them, if any.

`OnWriteDone()` reacts to a write completion. If the write was done
successfully, we continue to send the next `Feature` until `features_to_send_`
is empty, at which point we will call `Finish(Status::OK)` to finish the call.

`OnDone()` reacts to the RPC completion. We will do the final cleanup in
`OnDone()`.

`OnCancel()` reacts to the cancellation of the RPC. We log the occurrence of a
cancellation in this method.

### Client

Similar to the server side, the client side needs to implement some kind of
client reactor to interact with the server. A client reactor encapsulates all
the operations needed to process an RPC.

Since `ListFeatures` is server-streaming, we should implement a
`ClientReadReactor`, which has a name that is symmetric to `ServerWriteReactor`.

```c++
    class Reader : public grpc::ClientReadReactor<Feature> {
     public:
      Reader(RouteGuide::Stub* stub, float coord_factor,
             const routeguide::Rectangle& rect)
          : coord_factor_(coord_factor) {
        stub->async()->ListFeatures(&context_, &rect, this);
        StartRead(&feature_);
        StartCall();
      }
      void OnReadDone(bool ok) override {
        if (ok) {
          std::cout << "Found feature called " << feature_.name() << " at "
                    << feature_.location().latitude() / coord_factor_ << ", "
                    << feature_.location().longitude() / coord_factor_
                    << std::endl;
          StartRead(&feature_);
        }
      }
      void OnDone(const Status& s) override {
        std::unique_lock<std::mutex> l(mu_);
        status_ = s;
        done_ = true;
        cv_.notify_one();
      }
      Status Await() {
        std::unique_lock<std::mutex> l(mu_);
        cv_.wait(l, [this] { return done_; });
        return std::move(status_);
      }

     private:
      ClientContext context_;
      float coord_factor_;
      Feature feature_;
      std::mutex mu_;
      std::condition_variable cv_;
      Status status_;
      bool done_ = false;
    };
```

The `ClientReadReactor` is templatized with one parameter, `Feature`, which is
the type of response message from the server.

In the constructor of `Reader`, we pass the `ClientContext`, `&rectangle_` (the
request object), and the `Reader` to the RPC method
`stub->async()->ListFeatures()`. Then we pass the `&feature_` to `StartRead()`
to specify where to store the received response. Finally, we call `StartCall()`
to activate the RPC!

`OnReadDone()` reacts to read completion. If the read was done successfully, we
continue to read the next `Feature` until we fail to do so, indicated by `ok`
being `false`.

`OnDone()` reacts to the RPC completion. It checks the RPC status outcome and
notifies the conditional variable waiting for `OnDone()`.

`Await()` is not a method of `ClientReadReactor`. This is just added for
simplicity, so that the example knows that the RPC is done. Alternatively, if
there were no need for a notification on completion, `OnDone()` could simply
perform return after cleanup, for example, freeing up heap allocated objects.

To initiate an RPC, the client simply instantiates a `ReadReactor` and waits for
the RPC completion.

```c++
    routeguide::Rectangle rect;
    Feature feature;

    rect.mutable_lo()->set_latitude(400000000);
    rect.mutable_lo()->set_longitude(-750000000);
    rect.mutable_hi()->set_latitude(420000000);
    rect.mutable_hi()->set_longitude(-730000000);
    std::cout << "Looking for features between 40, -75 and 42, -73"
              << std::endl;

    Reader reader(stub_.get(), kCoordFactor_, rect);
    Status status = reader.Await();
    if (status.ok()) {
      std::cout << "ListFeatures rpc succeeded." << std::endl;
    } else {
      std::cout << "ListFeatures rpc failed." << std::endl;
    }
```

## Client-side streaming RPC

Once you understand the idea of server-side streaming RPC in the previous
section, you should find the client-side streaming RPC easy to learn.

`RecordRoute` is the client-side streaming RPC we will discuss. The client sends
a sequence of `Point`s to the server, and the server will return a
`RouteSummary` after the client has finished sending the `Point`s.

### Server

The RPC handler's interface for a client-side streaming RPC does not have any
input parameters, and its return type is a server reactor, namely, a
`ServerReadReactor`.

The `ServerReadReactor` has two template parameters: `Point` is the type of each
request message from the client; `RouteSummary` is the type of the response from
the server.

Similar to `ServerWriteReactor`, `ServerReadReactor` is the class that handles
an RPC.

```c++
grpc::ServerReadReactor<Point>* RecordRoute(CallbackServerContext* context,
                                              RouteSummary* summary) override {
    class Recorder : public grpc::ServerReadReactor<Point> {
     public:
      Recorder(RouteSummary* summary, const std::vector<Feature>* feature_list)
          : start_time_(system_clock::now()),
            summary_(summary),
            feature_list_(feature_list) {
        StartRead(&point_);
      }

      void OnReadDone(bool ok) override {
        if (ok) {
          point_count_++;
          if (!GetFeatureName(point_, *feature_list_).empty()) {
            feature_count_++;
          }
          if (point_count_ != 1) {
            distance_ += GetDistance(previous_, point_);
          }
          previous_ = point_;
          StartRead(&point_);
        } else {
          summary_->set_point_count(point_count_);
          summary_->set_feature_count(feature_count_);
          summary_->set_distance(static_cast<long>(distance_));
          auto secs = std::chrono::duration_cast<std::chrono::seconds>(
              system_clock::now() - start_time_);
          summary_->set_elapsed_time(secs.count());
          Finish(Status::OK);
        }
      }

      void OnDone() override {
        LOG(INFO) << "RPC Completed";
        delete this;
      }

      void OnCancel() override { LOG(ERROR) << "RPC Cancelled"; }

     private:
      system_clock::time_point start_time_;
      RouteSummary* summary_;
      const std::vector<Feature>* feature_list_;
      Point point_;
      int point_count_ = 0;
      int feature_count_ = 0;
      float distance_ = 0.0;
      Point previous_;
    };
    return new Recorder(summary, &feature_list_);
  }
```

The `ServerReadReactor`'s constructor is called when `RecordRoute()` constructs
and provides the reactor in response to the started RPC. The constructor stores
the `RouteSummary*` to return the response later, and initiates a read operation
by calling `StartRead(&point_)`.

`OnReadDone()` reacts to a read completion. If the read was done successfully,
we update the stats with the newly received `Point`, and continue to read next
`Point` until we fail to do so, indicated by `ok` being `false`. Upon read
failure, the server will set the response into `summary_` and call
`Finish(Status::OK)` to finish the RPC.

`OnDone()` reacts to the RPC completion. We will do the final cleanup in
`OnDone()`.

`OnCancel()` reacts to the cancellation of the RPC. We log the occurrence of a
cancellation in this method.

### Client

Unsurprisingly, we need to implement a client reactor for the client side, and
that client reactor is called `ClientWriteReactor`.

```c++
    class Recorder : public grpc::ClientWriteReactor<Point> {
     public:
      Recorder(RouteGuide::Stub* stub, float coord_factor,
               const std::vector<Feature>* feature_list)
          : coord_factor_(coord_factor),
            feature_list_(feature_list),
            generator_(
                std::chrono::system_clock::now().time_since_epoch().count()),
            feature_distribution_(0, feature_list->size() - 1),
            delay_distribution_(500, 1500) {
        stub->async()->RecordRoute(&context_, &stats_, this);
        // Use a hold since some StartWrites are invoked indirectly from a
        // delayed lambda in OnWriteDone rather than directly from the reaction
        // itself
        AddHold();
        NextWrite();
        StartCall();
      }
      void OnWriteDone(bool ok) override {
        // Delay and then do the next write or WritesDone
        alarm_.Set(
            std::chrono::system_clock::now() +
                std::chrono::milliseconds(delay_distribution_(generator_)),
            [this](bool /*ok*/) { NextWrite(); });
      }
      void OnDone(const Status& s) override {
        std::unique_lock<std::mutex> l(mu_);
        status_ = s;
        done_ = true;
        cv_.notify_one();
      }
      Status Await(RouteSummary* stats) {
        std::unique_lock<std::mutex> l(mu_);
        cv_.wait(l, [this] { return done_; });
        *stats = stats_;
        return std::move(status_);
      }

     private:
      void NextWrite() {
        if (points_remaining_ != 0) {
          const Feature& f =
              (*feature_list_)[feature_distribution_(generator_)];
          std::cout << "Visiting point "
                    << f.location().latitude() / coord_factor_ << ", "
                    << f.location().longitude() / coord_factor_ << std::endl;
          StartWrite(&f.location());
          points_remaining_--;
        } else {
          StartWritesDone();
          RemoveHold();
        }
      }
      ClientContext context_;
      float coord_factor_;
      int points_remaining_ = 10;
      Point point_;
      RouteSummary stats_;
      const std::vector<Feature>* feature_list_;
      std::default_random_engine generator_;
      std::uniform_int_distribution<int> feature_distribution_;
      std::uniform_int_distribution<int> delay_distribution_;
      grpc::Alarm alarm_;
      std::mutex mu_;
      std::condition_variable cv_;
      Status status_;
      bool done_ = false;
    };
```

The `ClientWriteReactor` is templatized with one parameter, `Point`, which is
the type of request message from the client.

In the constructor of `Recorder`, we pass the `ClientContext`, `&stats_` (the
response object), and the `Recorder` to the RPC method
s`stub->async()->RecordRoute()`. Then we add an operation to send the first
`Point` in `points_to_send_`, if any. Note that if there is nothing to send at
the startup of the RPC, we need to call `StartWritesDone()` to inform the server
that we are done with writes. Finally, calling `StartCall()` activates the RPC.

`OnWriteDone()` reacts to write completion. If the write was done successfully,
we continue to write the next `Point` until `points_to_send_` is empty. For the
last `Point` to send, we call `StartWriteLast()` to piggyback the signal that
writes are done. `StartWriteLast()` is effectively the same with combined
`StartWrite()` and `StartWritesDone()`, but is more efficient.

`OnDone()` reacts to the RPC completion. It checks the RPC status outcome and
the response in `stats_`, and notifies the conditional variable waiting for
`OnDone()`.

`Await()` is not a method of `ClientWriteReactor`. We add `Await()` so that the
caller can wait until the RPC is done.

To initiate an RPC, the client simply instantiates a `Recorder` and waits for
the RPC completion.

```c++
    Recorder recorder(stub_.get(), kCoordFactor_, &feature_list_);
    RouteSummary stats;
    Status status = recorder.Await(&stats);
    if (status.ok()) {
      std::cout << "Finished trip with " << stats.point_count() << " points\n"
                << "Passed " << stats.feature_count() << " features\n"
                << "Travelled " << stats.distance() << " meters\n"
                << "It took " << stats.elapsed_time() << " seconds"
                << std::endl;
    } else {
      std::cout << "RecordRoute rpc failed." << std::endl;
    }
```

## Bidirectional streaming RPC

Finally, we will look at the bidirectional streaming RPC `RouteChat`. In this
case, the client sends a sequence of `RouteNote`s to the server. Each time a
`RouteNote` at a `Point` is sent, the server will return a sequence of
`RouteNote`s at the same `Point` that have been sent by all the clients before.

### Server

Again, the RPC handler's interface for a bidirectional streaming RPC does not
have any input parameters, and its return type is a server reactor, namely, a
`ServerBidiReactor`.

The `ServerBidiReactor` has two template parameters, both of which are
`RouteNote`, because `RouteNote` is the message type of both request and
response. After all, `RouteChat` means to let clients chat and share information
with each other!

Since we have already discussed `ServerWriteReactor` and `ServerReadReactor`,
`ServerBidiReactor` should be quite straightforward.

```c++
  grpc::ServerBidiReactor<RouteNote, RouteNote>* RouteChat(
      CallbackServerContext* context) override {
    class Chatter : public grpc::ServerBidiReactor<RouteNote, RouteNote> {
     public:
      Chatter(absl::Mutex* mu, std::vector<RouteNote>* received_notes)
          : mu_(mu), received_notes_(received_notes) {
        StartRead(&note_);
      }

      void OnReadDone(bool ok) override {
        if (ok) {
          // Unlike the other example in this directory that's not using
          // the reactor pattern, we can't grab a local lock to secure the
          // access to the notes vector, because the reactor will most likely
          // make us jump threads, so we'll have to use a different locking
          // strategy. We'll grab the lock locally to build a copy of the
          // list of nodes we're going to send, then we'll grab the lock
          // again to append the received note to the existing vector.
          mu_->Lock();
          std::copy_if(received_notes_->begin(), received_notes_->end(),
                       std::back_inserter(to_send_notes_),
                       [this](const RouteNote& note) {
                         return note.location().latitude() ==
                                    note_.location().latitude() &&
                                note.location().longitude() ==
                                    note_.location().longitude();
                       });
          mu_->Unlock();
          notes_iterator_ = to_send_notes_.begin();
          NextWrite();
        } else {
          Finish(Status::OK);
        }
      }
      void OnWriteDone(bool /*ok*/) override { NextWrite(); }

      void OnDone() override {
        LOG(INFO) << "RPC Completed";
        delete this;
      }

      void OnCancel() override { LOG(ERROR) << "RPC Cancelled"; }

     private:
      void NextWrite() {
        if (notes_iterator_ != to_send_notes_.end()) {
          StartWrite(&*notes_iterator_);
          notes_iterator_++;
        } else {
          mu_->Lock();
          received_notes_->push_back(note_);
          mu_->Unlock();
          StartRead(&note_);
        }
      }

      RouteNote note_;
      absl::Mutex* mu_;
      std::vector<RouteNote>* received_notes_ ABSL_GUARDED_BY(mu_);
      std::vector<RouteNote> to_send_notes_;
      std::vector<RouteNote>::iterator notes_iterator_;
    };
    return new Chatter(&mu_, &received_notes_);
  }
```

The `ServerBidiReactor`'s constructor is called when `RouteChat()` constructs
and provides the reactor in response to the started RPC. The constructor
initiates a read operation by calling `StartRead(&received_note_)`.

`OnReadDone()` reacts to a read completion. If the read was done successfully
(i.e., `ok` is `true`), we will continue to read next `RouteNote`; otherwise, we
will record that reads are all finished, and finish the RPC. As for the newly
received `RouteNote` upon a successful read, we add it to `received_notes_`, and
append the previously received notes at the same `Point` to `to_send_notes_`.
Whenever `to_send_notes_` becomes non-empty, we start to send the `RouteNote`s
in `to_send_notes_`.

`OnWriteDone()` reacts to a write completion. If the write was done
successfully, we continue to send next `RouteNote` until `to_send_notes_` is
empty, at which point we will continue reading next `RouteNote` or finish the
RPC if reads are also finished.

`OnDone()` reacts to the RPC completion. We will do the final cleanup in
`OnDone()`.

`OnCancel()` reacts to the cancellation of the RPC. We log the occurrence of a
cancellation in this method.

### Client

Yes, the client reactor for a bidirectional streaming RPC is
`ClientBidiReactor`.

```c++
    class Chatter : public grpc::ClientBidiReactor<RouteNote, RouteNote> {
     public:
      explicit Chatter(RouteGuide::Stub* stub)
          : notes_{MakeRouteNote("First message", 0, 0),
                   MakeRouteNote("Second message", 0, 1),
                   MakeRouteNote("Third message", 1, 0),
                   MakeRouteNote("Fourth message", 0, 0)},
            notes_iterator_(notes_.begin()) {
        stub->async()->RouteChat(&context_, this);
        NextWrite();
        StartRead(&server_note_);
        StartCall();
      }
      void OnWriteDone(bool ok) override {
        if (ok) {
          NextWrite();
        }
      }
      void OnReadDone(bool ok) override {
        if (ok) {
          std::cout << "Got message " << server_note_.message() << " at "
                    << server_note_.location().latitude() << ", "
                    << server_note_.location().longitude() << std::endl;
          StartRead(&server_note_);
        }
      }
      void OnDone(const Status& s) override {
        std::unique_lock<std::mutex> l(mu_);
        status_ = s;
        done_ = true;
        cv_.notify_one();
      }
      Status Await() {
        std::unique_lock<std::mutex> l(mu_);
        cv_.wait(l, [this] { return done_; });
        return std::move(status_);
      }

     private:
      void NextWrite() {
        if (notes_iterator_ != notes_.end()) {
          const auto& note = *notes_iterator_;
          std::cout << "Sending message " << note.message() << " at "
                    << note.location().latitude() << ", "
                    << note.location().longitude() << std::endl;
          StartWrite(&note);
          notes_iterator_++;
        } else {
          StartWritesDone();
        }
      }
      ClientContext context_;
      const std::vector<RouteNote> notes_;
      std::vector<RouteNote>::const_iterator notes_iterator_;
      RouteNote server_note_;
      std::mutex mu_;
      std::condition_variable cv_;
      Status status_;
      bool done_ = false;
    };
```

The `ClientBidiReactor` is templatized with two parameters, the message types of
the request and the response, which are both `RouteNote` in the case of RPC
`RouteChat`.

In the constructor of `Chatter`, we pass the `ClientContext` and the `Chatter`
to the RPC method `stub->async()->RouteChat()`. Then we add an operation to send
the first `RouteNote` in `notes_`, if any. Note that if there is nothing to send
at the startup of the RPC, we need to call `StartWritesDone()` to inform the
server that we are done with writes. We also call `StartRead()` to add a read
operation. Finally, calling `StartCall()` activates the RPC.

`OnReadDone()` reacts to read completion. If the read was done successfully, we
continue to read next `RouteNote` until we fail to do so, indicated by `ok`
being `false`.

`OnWriteDone()` reacts to write completion. If the write was done successfully,
we continue to write next `RouteNote` until `notes_` is empty. For the last
`RouteNote` to send, we call `StartWriteLast()` to piggyback the signal that
writes are done. `StartWriteLast()` is effectively the same with combined
`StartWrite()` and `StartWritesDone()`, but is more efficient.

`OnDone()` reacts to the RPC completion. It checks the RPC status outcome and
the message stats, and notifies the conditional variable waiting for `OnDone()`.

`Await()` is not a method of `ClientBidiReactor`. We add `Await()` so that the
caller can wait until the RPC is done.

To initiate an RPC, the client simply instantiates a `Chatter` and waits for the
RPC completion.

```c++
    Chatter chatter(stub_.get());
    Status status = chatter.Await();
    if (!status.ok()) {
      std::cout << "RouteChat rpc failed." << std::endl;
    }
```
