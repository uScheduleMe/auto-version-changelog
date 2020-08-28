# Auto Increment Version and Generate Changelog

Using this GitHub action will enable auto changelog generation using
keywords at the start of commit messages, such as `{new,chg,fix,maj}:
my commit message`.  If a `maj` or `mjr` keyword is used, then the
major version of the repo is also automatically incremented.  If the
`new` tag is used, then the minor version is incremented.  Otherwise,
as long as any tag is used, the patch version is incremented.

Note that to use this you must have a `.version` file in the root of
your repo containing the semantic version of your project, like
```
VERSION=0.1.2
```

Furthermore, you must have a basic `CHANGELOG.md` in the root of your
repo, such as
```
## 0.1.2 (2020-08-22)

### Other

* Initialized
```

To enable this action, your workflow file currently requires three
steps:
1. To checkout the repo
1. To setup python 3.7
1. To call this action

Such a workflow would look something like
```yaml
on: [push]

jobs:
  auto_version_changelog:
    runs-on: ubuntu-latest
    steps:

      - id: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Setup python
        uses: actions/setup-python@v2
        with:
          python-version: '3.7'

      - name: Make commit for auto-generated changelog
        uses: uScheduleMe/auto-version-changelog@other
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
