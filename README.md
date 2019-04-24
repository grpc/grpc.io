# The gRPC website and documentation

This repository houses the assets used to build and deploy the gRPC website, available at https://grpc.io. The site is built using the [Hugo](https://gohugo.io) static site generator. Check out the [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/) for a quick intro.

## Running the site locally

To run the site locally, you need to [install Hugo](https://gohugo.io/getting-started/installing). Once Hugo is installed:

```bash
make serve
```

Alternatively, you can run the site using a [Docker](https://docker.com) container:

```bash
make docker-serve
```

## Publishing the site

The gRPC website is automatically published by [Netlify](https://netlify.com). Any time changes are pushed to the `master` branch, the site is re-built and re-deployed. This process does not require manual management.

## Site content

All of the [Markdown](https://www.markdownguide.org/) content used to build the site's documentation, blog, etc. is in the [`content`](./content) directory.