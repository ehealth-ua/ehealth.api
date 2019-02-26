We welcome everyone to contribute to ehealth.api.
The project is written in [Elixir language](https://elixir-lang.org/) and its best practicies are applied to this project.


## Setup

Environment requirements:

- elixir 1.8+
- postgresql 9.6+
- postgis extension
- redis

```bash
$ git clone git@github.com:edenlabllc/ehealth.api.git
$ mix deps.get
$ mix test
```

Once tests are passed, you're ready to make your contribution.

## Branches

`develop` - main development branch

`preprod` - used for demo/preprod environments

`master` - branch for use to production deploy, should always reflect production state.

All new branches should be created from `develop` and PR's opened into `develop` branches.

## Tags

Tags seems useless with umbrella app, we can't rely on them anymore.

## Create a PR

1. Fork repository
2. Create a feature branch from `develop`
3. Commit your changes
4. Push back to your repository
5. Create a PR to `ehealth.api`

## PR review rules

There are some general contribution rules we follow to keep each PR easy to understand and manage:

1. PR shouldn't be large. Thousands of lines can't be easily reviewed and merged with confidence. Keep is as simple as possible.
2. PR should either fix existing issue or implement a documented feature. We probably won't merge features not included in roadmap.
In case a new bug is found, please report an issue before starting a PR.
PR must be linked with an [issue](https://github.com/edenlabllc/ehealth.api/issues)
3. Write tests. We keep tests coverage about 90%, the PR shouldn't decrease that value. Each bug or feature should be covered with appropriate tests.
4. Naming rules. Use [Elixir naming conventions](https://github.com/elixir-lang/elixir/blob/master/lib/elixir/pages/Naming%20Conventions.md)
5. Use pattern matching where it's possible.
6. Since `ehealth.api` is just a single microservice among many others, to test requests between them we use a [Mox library](https://github.com/plataformatec/mox).
That means sometimes you need to refer to different repository to understand how to mock the request response.
7. Environment variables should be used for the application configuration. Whenever you add new configuration parameter, it should be added to the [docs/environment.md] documentation of the respective application.

We use [travis.ci](https://travis-ci.org/) as CI engine. Each PR triggers travis builds which run tests and build docker images.
So, to be able to merge the PR, tests should pass and image should be able to build.
Furthermore, we use Elixir formatter to format the code and [credo](https://github.com/rrrene/credo/) as static code analysis tool.
Before creating a PR, you can verify that:

```
mix test
mix format
mix credo --strict
```

If one of them fail, travis build will fail too and PR can't be merged.

## How to set up system from scratch
[Step-by-step manual](https://github.com/edenlabllc/ehealth.demo.charts) how to run the cluster from scratch with the recommended default env. vars values

## Hot fix

To create a hotfix, you need to create a branch from the `master`, apply a hotfix and create a PR back to master.
For code consistency, you should apply the same commit to `develop` and `preprod` branches.

## Release

1. Pull the latest `develop` and `preprod` branches
2. Create a `release` branch from `develop`
3. Rebase a `release` branch on `preprod` branch
4. Push to github and create a PR from `release` to `preprod`
5. Use `rebase and merge` button to merge a PR
6. Run `release.sh` locally to create an image and push to dockerhub (this part is done by devops)
7. Created image can be deployed to demo/preprod/prod
