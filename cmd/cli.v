module main

import anki
import dictionary
import dictionary.mw
import envars
import io
import os

fn main() {
	env := envars.load() ?

	mut br := io.new_buffered_reader(
		reader: os.stdin()
	)
	mut out := os.stdout()
	learners := mw.new_learners(env.mw_learners_key)
	for {
		if word := br.read_line() {
			req := learners.lookup_request(word)
			result := learners.to_dictionary_result(word, mw.parse_response((req.do() ?).text) ?)
			cards := anki.to_basic_card(result)
			for card in cards {
				out.writeln(card.front + '\t' + card.back.replace_each(['\r', '', '\n', ''])) or {}
			}
		} else {
			break
		}
	}
	out.flush()
}
