# gRPC website

The [grpc.io][] site, built using [Hugo][] and hosted on [Netlify][].

## Build prerequisites

To build and serve the site, you'll need the latest [LTS release][] of **Node**.
Like Netlify, we use **[nvm][]**, the Node Version Manager, to install and
manage Node versions:

```console
$ nvm install --lts
```

## Setup

 1. Clone or download a copy of this repo.
 2. From a terminal window, change to the cloned or unzipped repo directory.
 3. Get NPM packages and git submodules, including the the [Docsy][] theme:
    ```console
    $ npm install 
    ```

## Build the site

Run the following command to have Hugo generate the site files:

```console
$ npm run build
```

You'll find the generated site files in the `public` folder.

## Serve the site locally


To locally serve the site at [localhost:8888][], run the following command:

```console
$ npm run serve
```

## Site deploys and PR previews

If you submit a PR, Netlify will automatically create a [deploy preview][] so
that you can review your changes. Once your PR is merged, Netlify automcatically
deploys to the production site [grpc.io][].

> **Note**: PR previews include _draft pages_, but production builds do not.

You can see deploy logs and more from the [Netlify gRPC Team dashboard][],
provided you have the necessary permissions.

## Contribute

We welcome issues and PRs! For details, see [Contribute][].

[Contribute]: https://grpc.io/community/#contribute
[deploy preview]: https://www.netlify.com/blog/2016/07/20/introducing-deploy-previews-in-netlify/
[Docsy]: https://www.docsy.dev
[grpc.io]: https://grpc.io
[Hugo]: https://gohugo.io
[localhost:8888]: http://localhost:8888
[LTS release]: https://nodejs.org/en/about/releases/
[Netlify gRPC Team dashboard]: https://app.netlify.com/teams/grpc/overview
[Netlify]: https://netlify.com
[nvm]: https://github.com/nvm-sh/nvm/blob/master/README.md#installing-and-updating
