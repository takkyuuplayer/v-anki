module anki

import dictionary

pub struct Card {
pub:
	front string
	back  string
}

pub fn to_basic_card(result dictionary.Result) ?[]Card {
	if result.entries.len == 0 {
		return error('no entries for $result.word')
	}

	front := result.word
	back := to_basic_back(result)

	return [
		Card{front, back},
	]
}

fn to_basic_back(result dictionary.Result) string {
	// TODO: HTML escape
	return $tmpl('templates/basic.html')
}
