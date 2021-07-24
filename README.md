# v-anki

![CI](https://github.com/takkyuuplayer/v-anki/workflows/CI/badge.svg)

Generate TSV to import into [Anki](https://apps.ankiweb.net/).

## Usage

### Prerequisite

1. Sign up [Merriam\-Webster Dictionary API](https://www.dictionaryapi.com/) and get a Learner's key and a Collegiate key.
2. `cp .env.sample .env`
3. Replace `.env` file's keys with your own ones.

### CLI

#### basic card

```bash
cat words.txt | anki cli > anki.tsv
```

#### example sentences card

```bash
cat words.txt | anki cli -card=sentences > anki.tsv
```

## Supported Dictionaries

- Merriam-Webster
  - [Learners Dictionary API \| Merriam\-Webster Dictionary API](https://dictionaryapi.com/products/api-learners-dictionary)
  - [Collegiate Dictionary API \| Merriam\-Webster Dictionary API](https://dictionaryapi.com/products/api-collegiate-dictionary)
