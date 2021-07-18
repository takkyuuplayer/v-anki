module anki

import io
import dictionary
import sync

interface Writer {
	writeln(string) ?int
	flush()
}

const concurrency = 10

pub fn run(dictionaries []dictionary.Dictionary, reader io.Reader, writer Writer) {
	mut br := io.new_buffered_reader(
		reader: reader
	)

	ch := chan bool{cap: anki.concurrency}
	defer {
		ch.close()
	}
	mut wg := sync.new_waitgroup()
	mut mu := sync.new_mutex()

	for {
		line := br.read_line() or { break }
		word := line.trim_space()
		if word == '' {
			continue
		}
		ch <- true
		wg.add(1)

		go run_on_word(dictionaries, reader, writer, word, ch, mut wg, mut mu)
	}

	wg.wait()

	writer.flush()
}

fn run_on_word(dictionaries []dictionary.Dictionary, reader io.Reader, writer Writer, word string, ch chan bool, mut wg sync.WaitGroup, mut mu sync.Mutex) {
	defer {
		_ = <-ch
		wg.done()
	}

	for dict in dictionaries {
		lookedup := dict.lookup(word) or { continue }
		cards := to_basic_card(lookedup)
		if cards.len == 0 {
			continue
		}
		for card in cards {
			mu.@lock()
			defer {
				mu.unlock()
			}

			// TODO csv escape
			writer.writeln(card.front + '\t' + card.back.replace_each(['\r', ' ', '\n', ' '])) or {}
			return
		}
	}
	eprintln(word + '\t' + 'Not Found')
}
