module anki

import io
import dictionary
import sync
import csvenc

struct Runner {
	dictionaries []dictionary.Dictionary
	to_card      ToCard
}

pub fn new(dictionaries []dictionary.Dictionary, to_card ToCard) Runner {
	return Runner{dictionaries, to_card}
}

const concurrency = 10

pub fn (r Runner) run(reader io.Reader, mut writer io.Writer, mut err_writer io.Writer) {
	mut br := io.new_buffered_reader(
		reader: reader
	)

	ch := chan bool{cap: anki.concurrency}
	defer {
		ch.close()
	}
	mut wg := sync.new_waitgroup()
	mut mu := sync.new_mutex()
	mut csv_writer := csvenc.new_writer(writer: writer, delimiter: `\t`) or { panic(err) }
	mut csv_err_writer := csvenc.new_writer(writer: err_writer, delimiter: `\t`) or { panic(err) }

	for {
		word := (br.read_line() or { break }).trim_space()
		if word == '' {
			continue
		}
		ch <- true
		wg.add(1)

		r.run_on_word(mut csv_writer, mut csv_err_writer, word, ch, mut wg, mut mu)
	}

	wg.wait()
	csv_writer.flush() or {}
	csv_err_writer.flush() or {}
}

fn (r Runner) run_on_word(mut writer csvenc.Writer, mut err_writer csvenc.Writer, word string, ch chan bool, mut wg sync.WaitGroup, mut mu sync.Mutex) {
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
			writer.write([remove_new_lines(card.front), remove_new_lines(card.back)]) or {}
			mu.unlock()
		}
		return
	}

	mu.@lock()
	err_writer.write(['NotFound', word]) or {}
	mu.unlock()
}

fn remove_new_lines(s string) string {
	return s.replace_each(['\r', ' ', '\n', ' '])
}
