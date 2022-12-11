module anki

import dictionary

pub struct Card {
pub:
	front string
	back  string
}

type ToCard = fn (dictionary.Result) []Card

pub fn to_card(to_lookup dictionary.ToLookup, card_type string) !ToCard {
	if card_type == 'sentences' {
		return to_sentences_card
	} else if card_type == 'entries' {
		return to_entries_card
	} else if card_type == 'basic' {
		if to_lookup == dictionary.ToLookup.word {
			return to_all_in_one_card
		} else {
			return to_entries_card
		}
	} else {
		return error('$card_type not found')
	}
}
