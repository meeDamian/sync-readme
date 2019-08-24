# sync-readme
Github Action to sync `README.md` from Github to Docker Hub

# Usage

See [action.yml](action.yml)

Basic (share the same `README.md` between Github, and Docker Hub):

```yaml
steps:
- uses: actions/checkout@master

- uses: meeDamian/sync-readme@v1.0
  with:
    user: ${{ secrets.DOCKER_USER }}
    pass: ${{ secrets.DOCKER_PASS }}
    slug: ${{ github.repository }}
```

Use custom description on a Docker Hub repo with different path than Github repo:
```yaml

steps:
- uses: actions/checkout@master

- uses: meeDamian/sync-readme@v1.0
  with:
    user: ${{ secrets.DOCKER_USER }}
    pass: ${{ secrets.DOCKER_PASS }}
    slug: organization/image-name
    readme: ./docker/description.md
```

> **NOTE:** Docker Hub requires `user`, and `slug` to be lowercase. You **don't have to** provide it in lower case, as automatic conversion is done [here](https://github.com/meeDamian/sync-readme/blob/master/entrypoint.sh#L38-L41).
>
> **NOTE_2:** `master` branch may sometimes be broken, or change behavior.  It's highly recommended to always use [tags](https://github.com/meeDamian/sync-readme/tags).

# License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
