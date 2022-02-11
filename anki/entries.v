module anki

import dictionary

pub fn to_entries_card(result dictionary.Result) []Card {
	if result.entries.len == 0 {
		return []
	}

	mut cards := []Card{}

	for entry in result.entries {
		front := entry.headword
		back := to_all_in_one_back(dictionary.Result{
			word: result.word
			dictionary: result.dictionary
			web_url: result.web_url
			entries: [entry]
		})
		cards << Card{front, back}
	}

	return cards
}
