module anki

import io
import dictionary
import sync

struct Runner {
	dictionaries []dictionary.Dictionary
	to_card      ToCard
}

pub fn new(dictionaries []dictionary.Dictionary, to_card ToCard) Runner {
	return Runner{dictionaries, to_card}
}

const concurrency = 10

pub fn (r Runner) run(reader io.Reader, writer io.Writer) {
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
		word := (br.read_line() or { break }).trim_space()
		if word == '' {
			continue
		}
		ch <- true
		wg.add(1)

		go r.run_on_word(reader, writer, word, ch, mut wg, mut mu)
	}

	wg.wait()
}

fn (r Runner) run_on_word(reader io.Reader, writer io.Writer, word string, ch chan bool, mut wg sync.WaitGroup, mut mu sync.Mutex) {
	defer {
		_ = <-ch
		wg.done()
	}

	for dict in r.dictionaries {
		lookedup := dict.lookup(word) or { continue }
		cards := r.to_card(lookedup)
		if cards.len == 0 {
			continue
		}
		for card in cards {
			mu.@lock()

			// TODO csv escape
			line := remove_new_lines(card.front) + '\t' + remove_new_lines(card.back) + '\n'
			writer.write(line.bytes()) or {}
			mu.unlock()
		}
		return
	}
	eprintln('NotFound\t$word')
}

fn remove_new_lines(s string) string {
	return s.replace_each(['\r', ' ', '\n', ' '])
}
