<span align="center">

[![Python](https://img.shields.io/badge/Python-3.13+-blue.svg)](https://www.python.org/downloads/)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/billwallis/billiam-data-stack/main.svg)](https://results.pre-commit.ci/latest/github/billwallis/billiam-data-stack/main)
[![GitHub last commit](https://img.shields.io/github/last-commit/billwallis/billiam-data-stack)](https://shields.io/badges/git-hub-last-commit)

</span>

---

# Billiam Data Stack

Analytical data stack for life admin.

Supersedes https://github.com/billwallis/billiam-database.

## Contributing

Install the dependencies:

```shell
python -m venv .venv/
source .venv/bin/activate

pip install --editable . --group dev
pre-commit install --install-hooks
```
