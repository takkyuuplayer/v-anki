module anki

import dictionary

pub struct Card {
pub:
	front string
	back  string
}

type ToCard = fn (dictionary.Result) []Card

pub const to_card = {
	'basic':     to_basic_card
	'sentences': to_sentences_card
}
