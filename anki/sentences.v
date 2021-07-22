module anki

import dictionary

pub fn to_sentences_card(result dictionary.Result) []Card {
	if result.entries.len == 0 {
		return []
	}

	mut cards := []Card{}

	for entry in result.entries {
		for definition in entry.definitions {
			if definition.sense == '' || definition.examples.len == 0 {
				continue
			}
			front := to_sentences_front(definition)
			back := to_basic_back(dictionary.Result{
				word: result.word
				dictionary: result.dictionary
				web_url: result.web_url
				entries: [dictionary.Entry{
					id: entry.id
					headword: entry.headword
					function_label: entry.function_label
					grammatical_note: entry.grammatical_note
					pronunciation: entry.pronunciation
					inflections: entry.inflections
					definitions: [definition]
					variants: entry.variants
				}]
			})
			cards << Card{front, back}
		}
	}

	return cards
}

fn to_sentences_front(definition dictionary.Definition) string {
	return $tmpl('templates/sentences.html')
}
