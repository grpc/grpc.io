# The gRPC website and documentation

This repository houses the assets used to build and deploy the gRPC website, available at https://grpc.io. The site is built using the [Hugo](https://gohugo.io) static site generator. Check out the [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/) for a quick intro.

## Prerequisites

- **[Hugo, extended version][hugo-install]**
- **[nvm][]**, the Node Version Manager

## Serving the site locally

First install NPM packages:

```console
$ npm install
```

To build and locally serve this site, you can use **any one** of the following
commands:

- Build and serve using [Hugo][], via `make`:

  ```console
  $ make serve
  ```

- Build and serve using [Netlify dev][], which allows you to exercise features
  such as site redirects:

  ```console
  $ npx netlify dev
  ```

- Alternatively, you can run the site using a [Docker](https://docker.com) container:

  ```console
  $ make docker-serve
  ```

## Publishing the site

The gRPC website is _automatically_ published by [Netlify][]. Any time changes
are pushed to the `master` branch, the site is rebuilt and redeployed.

## Site content

All of the [Markdown](https://www.markdownguide.org) content used to build the site's documentation, blog, etc. is in the [content](content) directory.

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

[Hugo]: https://gohugo.io
[hugo-install]: https://gohugo.io/getting-started/installing
[Netlify]: https://netlify.com
[Netlify dev]: https://www.netlify.com/products/dev
[nvm]: https://github.com/nvm-sh/nvm/blob/master/README.md#installing-and-updating
