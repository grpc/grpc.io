# The gRPC website and documentation

This repository houses the assets used to build and deploy the gRPC website, available at https://grpc.io. The site is built using the [Hugo](https://gohugo.io) static site generator. Check out the [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/) for a quick intro.

## Serving the site locally

To build and locally serve this site, you need to [install Hugo, extended version](https://gohugo.io/getting-started/installing). Once Hugo is installed:

```bash
make serve
```

Alternatively, you can run the site using a [Docker](https://docker.com) container:

```bash
make docker-serve
```

## Publishing the site

The gRPC website is _automatically_ published by [Netlify](https://netlify.com). Any time changes are pushed to the `master` branch, the site is rebuilt and redeployed.

## Site content

All of the [Markdown](https://www.markdownguide.org) content used to build the site's documentation, blog, etc. is in the [`content`](content) directory.

## Checking links

You can check the site's internal links by running this command:

```bash
make check-internal-links
```

This deletes the generated `public` directory, builds the "production" version of the site, and verifies that internal links are valid. Please note that internal links prefixed with `/grpc` do not work in your local environment (there are redirects applied by [Netlify](https://netlify.com)). Any errors returned from `/grpc` links are false negatives that you can ignore.
