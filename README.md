# v-anki

![CI](https://github.com/takkyuuplayer/v-anki/workflows/CI/badge.svg)

Generate TSV to import into [Anki](https://apps.ankiweb.net/).

## Usage

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
