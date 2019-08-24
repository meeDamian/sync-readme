# sync-readme
Github Action to sync `README.md` from Github to Docker Hub

# Usage

See [action.yml](action.yml)


#### Minimal

If your `user`-name, and the repo path (`slug`) are both the same on Github and Docker Hub, and `README.md` is located at repo's root, it's enough to:

```yaml
steps:
- uses: actions/checkout@master

- uses: meeDamian/sync-readme@v1.0.1
  with:
    pass: ${{ secrets.DOCKER_PASS }}
```

#### All custom

If everything needs to be specified: 

```yaml

steps:
- uses: actions/checkout@master

- uses: meeDamian/sync-readme@v1.0.1
  with:
    user: docker-username
    pass: ${{ secrets.DOCKER_PASS }}
    slug: organization/image-name
    readme: ./docker/description.md
```

> **NOTE:** Add Docker Hub password to "Secrets" section in your repo's settings.
 
> **NOTE_1:** Docker Hub requires `user`, and `slug` to be lowercase.  Conversion [is done] automatically for you, so that Github's `meeDamian` becomes `meedamian` when passed to Docker.

> **NOTE_2:** `master` branch may sometimes be broken, or change behavior.  It's highly recommended to always use [tags].

[is done]: https://github.com/meeDamian/sync-readme/blob/master/entrypoint.sh#L34-L38
[tags]: https://github.com/meeDamian/sync-readme/tags

# License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
