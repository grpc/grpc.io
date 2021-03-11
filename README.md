# gRPC website

The [grpc.io][] site, built using [Hugo][] and hosted on [Netlify][].

## Build prerequisites

### 1. Install the following tools

- **[Hugo, extended edition][hugo-install]**; match the version specified in
  [netlify.toml](netlify.toml)
- **Node**, the latest [LTS release][]. Like Netlify, we use **[nvm][]**, the
  Node Version Manager, to install and manage Node versions:
  ```console
  $ nvm install --lts
  $ nvm use --lts
  ```

### 2. Clone this repo _and_ its submodules

> IMPORTANT: This repo has **recursive git _submodules_**, which affects how you
> clone it.

The _simplest_ way to get a full copy of this repo is to clone the repo _and_
its submodules _at the same time_ by running this command from a command shell /
window:

```console
$ git clone --recurse-submodules https://github.com/grpc/grpc.io.git
```
### 3. Change directories

From this point on you'll be working from the `grpc.io` directory:

```console
$ cd grpc.io
```
### 4. Did you get the submodules?

Forgetting to clone the submodules is a common error.

If you forgot the `--recurse-submodules` option when you ran the `clone` command
given in step 2 above or, if you cloned the repo using another method, as
described in [Cloning a repository][], then you'll need to fetch the repo's
submodules.

To (recursively) fetch the submodules, run the following command from the
`grpc.io` directory:

```console
$ git submodule update --init --recursive --depth 1
```

> NOTE: Unsure if you've fetched the submodules? The Git command above is
> idempotent, so you can safely (re-)run it -- if you already have the
> submodules, it will have no effect.

### 5. Run installation scripts

Install NPM packages:

```console
$ npm install
```

## Build the site

Run the following command to have Hugo generate the site files:

```console
$ hugo
```

The `public` folder contains the generated site.

## Serve the site locally

To locally serve this site, use **one** of the following commands.

> **Note**: Hugo serves pages from memory by default, so if you want to
> (re-)generate the website files to disk, use the build command above.

### a) Serve using [Hugo][] via `make`

```console
$ make serve
hugo server
Start building sites …
...
Environment: "development"
Serving pages from memory
...
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

This generates _unminified_ site pages. Other [Makefile](Makefile) targets
include the following:

- `serve-drafts` to also serve draft and future pages
- `serve-production` to server files exactly as they'll appear in production

### b) Serve using Netlify dev

[Netlify dev][] uses Hugo under the hood to serve the site, but it also creates
a proxy (at port 8888 by default), to handle [site redirects][]:

```console
$ npx netlify dev
```

If you also want to serve draft and future pages use this command:

```console
$ npx netlify dev -c "hugo serve -DFw"
```

## Site deploys and PR previews

Commits to the `main` branch are _automatically_ published by [Netlify][]. You
can see deploy logs and more from the [Netlify gRPC Team dashboard][], provided
you have the necessary permissions.

_PR previews_ are automatically built by [Netlify][] as well. By default, a PR
preview is identical to a production build.

If you want draft and future pages to also appear in a PR preview, then make
sure that the word "draft" appears in the branch name used to create the PR.

## Checking links

You can check the site's internal links by running this command:

```console
$ make check-internal-links
```

This deletes the generated `public` directory, builds the "production" version
of the site, and verifies that internal links are valid. Please note that
internal links prefixed with `/grpc` do not work in your local environment
(there are redirects applied by [Netlify](https://netlify.com)). Any errors
returned from `/grpc` links are false negatives that you can ignore.

[Cloning a repository]: https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository
[grpc.io]: https://grpc.io
[Hugo]: https://gohugo.io
[hugo-install]: https://gohugo.io/getting-started/installing
[LTS release]: https://nodejs.org/en/about/releases/
[Netlify]: https://netlify.com
[Netlify dev]: https://www.netlify.com/products/dev
[Netlify gRPC Team dashboard]: https://app.netlify.com/teams/grpc/overview
[nvm]: https://github.com/nvm-sh/nvm/blob/master/README.md#installing-and-updating
[site redirects]: layouts/index.redirects
