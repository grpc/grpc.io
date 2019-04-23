---
author: Doug Fawley, gRPC-Go TL
company: Google
company-link: google.com
date: "2018-01-22T00:00:00Z"
published: true
title: 2018-01-19 gRPC-Go Engineering Practices
---

It's the start of the new year, and almost the end of my first full year on the
gRPC-Go project, so I'd like to take this opportunity to provide an update on
the state of gRPC-Go development and give some visibility into how we manage the
project.  For me, personally, this is the first open source project to which
I've meaningfully contributed, so this year has been a learning experience for
me.  Over this year, the team has made constant improvements to our work habits
and communication.  I still see room for improvement, but I believe we are in a
considerably better place than we were a year ago.

<!--more-->

## Repo Health

When I first joined the gRPC-Go team, they had been without their previous
technical lead for a few months.  At that time, we had 45 open PRs, the oldest
of which was over a year old at the time.  As a new team member and maintainer,
the accumulation of stale PRs made it difficult to assess priorities and
understand the state of things.  For our contributors, neglecting PRs was both
disrespectful and an inconvenience when we started asking for rebases due to
other commits.  To resolve this, we made a concerted effort to either merge or
close all of those PRs, and we now hold weekly meetings to review the status of
every active PR to prevent the situation from reoccurring.

At the same time, we had 103 open issues, many of which were already fixed or
outdated or untriaged.  Since then, we fixed or closed 85 of those and put in
place a process to ensure we triage and prioritize new issues on a weekly
rotation.  Similarly to our PRs, we also review our assigned and high-priority
issues in a weekly meeting.

Our ongoing SLO for new issues and PRs is 1 week to triage and first response.

We also revamped our [labels](https://github.com/grpc/grpc-go/labels) for issues
and PRs to help with organization.  We typically apply a priority (P0-P3) and a
type (e.g. Bug, Feature, or Performance) to every issue.  We also have a
collection of status labels we apply in various situations.  The type labels are
also applied to PRs to aid in generating our release notes.

## Versioning and Backward Compatibility

We have recently documented our [versioning
policy](https://github.com/grpc/grpc-go/blob/master/Documentation/versioning.md).
Our goal is to maintain full backward compatibility except in limited
circumstances, including experimental APIs and mitigating security risks (most
notably [#1392](https://github.com/grpc/grpc-go/pull/1392)). If you notice a
behavior regression, please don't hesitate to [open an
issue](https://github.com/grpc/grpc-go/issues/new) in our repo (please [be
reasonable](https://xkcd.com/1172/)).

## gRFC

The [gRPC proposal repo](https://github.com/grpc/proposal) contains proposals
for substantial feature changes for gRPC that need to be designed upfront,
called gRFCs.  The purpose of this process is to provide visibility and solicit
feedback from the community.  Each change is discussed on our [mailing
list](https://groups.google.com/forum/#!forum/grpc-io) and debated before the
change is made.  We leveraged this before making the
backward-compatibility-breaking metadata change ([gRFC
L7](https://github.com/grpc/proposal/blob/master/L7-go-metadata-api.md)), and
also for designing the new resolver/balancer API ([gRFC
L9](https://github.com/grpc/proposal/pull/30)).

## Regression Testing

Every PR in our repo must pass our unit and end-to-end tests.  Our current test
coverage is 85%.  Anytime a regression is identified, we add a test that covers
the failing scenario, both to prove to ourselves that the problem is resolved by
the fix, and to prevent it from reoccurring in the future.  This helps us
improve our overall coverage numbers as well.  We also intend to re-enable
coverage reporting for all PRs, but in a non-blocking fashion ([related
issue](https://github.com/grpc/grpc-go/issues/1676)).

In addition to testing for correctness, any PR that we suspect will impact
performance is run though our benchmarks.  We have a set of benchmarks both in
our [open source repo](https://github.com/grpc/grpc-go/tree/master/benchmark)
and also within Google.  These comprise a variety of workloads that we believe
are most important for our users, both streaming and unary, and some are
specifically designed to measure our optimal QPS, throughput, or latency.

## Releases

The GA release of gRPC-Go was made in conjunction with the other languages in
July of 2016.  The team performed several patch releases between then and the
end of 2016, but none included release notes.  Our subsequent releases have
improved in regularity (a minor release is performed every six weeks) and
in the quality of the release notes.  We also are responsive with patch
releases, back-porting bug fixes to older releases either on demand or for more
serious issues within a week.

When performing a release, in addition to the tests in our repo, we also run a
full suite of inter-op tests with other gRPC language implementations.  This
process has been working well for us, and we will cover more about this in a
future blog post.

## Non-Open Source Work

We have taken an "open source first" approach to developing gRPC.  This means
that, wherever possible, gRPC functionality is added directly into the open
source project.  However, to work within Google's infrastructure, our team
sometimes needs to provide additional functionality on top of gRPC.  This is
typically done through hooks like the [stats
API](https://godoc.org/google.golang.org/grpc/stats#Handler) or
[interceptors](https://godoc.org/google.golang.org/grpc#UnaryClientInterceptor)
or [custom resolvers](https://godoc.org/google.golang.org/grpc/resolver).

To keep Google's internal version of gRPC up-to-date with the open source
version, we do weekly or on-demand imports.  Before an import, we run every test
within Google that depends upon gRPC.  This gives us another way in which we can
catch problems before performing releases in Open Source.

## Looking Forward

In 2018, we intend to do more of the same, and maintain our SLOs around
addressing issues and accepting contributions to the project.  We also would
like to more aggressively tag issues with the ["Help
Wanted"](https://github.com/grpc/grpc-go/labels/Status%3A%20Help%20Wanted) label
for anyone looking to contribute to have a bigger selection of issues to choose
from.

For gRPC itself, one of our main focuses right now is performance, which we hope
will transparently benefit many of our users.  In the near-term, we have some
exciting changes we're wrapping up that should provide a 30+% reduction in
latency with high concurrency, resulting in a QPS improvement of ~25%.  Once
that work is done, we have a list of other [performance
issues](https://github.com/grpc/grpc-go/issues?q=is%3Aissue+is%3Aopen+label%3A%22Type%3A+Performance%22)
that we'll be tackling next.

On user experience, we want to provide better documentation, and are starting to
improve our godoc with better comments and more examples.  We want to improve
the overall experience of using gRPC, so we will be working closely on projects
around distributed tracing, monitoring, and testing to make gRPC services easier
to manage in production.  We want to do more, and we are hoping that starting
with these and listening to feedback will help us ship improvements steadily.
