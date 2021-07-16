module anki

import io
import dictionary

interface Writer {
	writeln(string) ?int
	flush()
}

pub fn run(dictionaries []dictionary.Dictionary, reader io.Reader, writer Writer) {
	mut br := io.new_buffered_reader(
		reader: reader
	)

	for {
		if word := br.read_line() {
			for dict in dictionaries {
				if result := dict.lookup(word) {
					cards := to_basic_card(result)
					for card in cards {
						// TODO csv escape
						writer.writeln(card.front + '\t' +
							card.back.replace_each(['\r', ' ', '\n', ' '])) or {}
					}
					break
				}
			}
		} else {
			break
		}
	}
	writer.flush()
}
