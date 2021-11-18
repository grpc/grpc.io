# gRPC website

The [grpc.io][] site, built using [Hugo][] and hosted on [Netlify][].

## Build prerequisites

To build and serve the site, you'll need the latest [LTS release][] of **Node**.
Install it using **[nvm][]**, for example:

```console
$ nvm install --lts
```

## Setup

 1. Clone this repo.
 2. From a terminal window, change to the cloned repo directory.
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

If you submit a PR, Netlify will create a [deploy preview][] so that you can
review your changes. Once your PR is merged, Netlify deploys the updated site to
the production server.

> **Note**: PR previews include _draft pages_, but production builds do not.

To see deploy logs and more, visit project's [dashboard][] -- Netlify login
required.

## Check links

If you have [htmltest][] in your path, then
you can check the site's **internal** links by running this command:

```console
$ npm run check-links
```

You can check all links (internal and external) as well:

```console
$ npm run check-links:all
```

## Contribute

We welcome issues and PRs! For details, see [Contribute][].

[Contribute]: https://grpc.io/community/#contribute
[dashboard]: https://app.netlify.com/teams/grpc/overview
[deploy preview]: https://www.netlify.com/blog/2016/07/20/introducing-deploy-previews-in-netlify/
[Docsy]: https://www.docsy.dev
[grpc.io]: https://grpc.io
[htmltest]: https://github.com/wjdp/htmltest
[Hugo]: https://gohugo.io
[localhost:8888]: http://localhost:8888
[LTS release]: https://nodejs.org/en/about/releases/
[Netlify]: https://netlify.com
[nvm]: https://github.com/nvm-sh/nvm/blob/master/README.md#installing-and-updating
