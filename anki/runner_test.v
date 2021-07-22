module anki

import dictionary
import strings

fn test_run() ? {
	{
		// basic
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{}
		mut reader := MockReader{
			s: 'test\n\ntest'.bytes()
		}
		mut writer := MockWriter{}
		runner := new(dictionaries, to_basic_card)
		runner.run(reader, writer)

		cards := to_basic_card(anki.result)
		line := cards[0].front + '\t' + cards[0].back.replace_each(['\r', ' ', '\n', ' '])

		assert writer.sb.str() == '$line\n$line\n'
	}
}

struct MockReader {
	s []byte
mut:
	i int
}

fn (mut m MockReader) read(mut buf []byte) ?int {
	if m.i >= m.s.len {
		return 0
	}
	n := copy(buf, m.s[m.i..])
	m.i += n
	return n
}

struct MockWriter {
mut:
	sb strings.Builder
}

fn (mut m MockWriter) writeln(s string) ?int {
	m.sb.writeln(s)
	return s.bytes().len
}

fn (m MockWriter) flush() {
}

struct MockDictionary {}

fn (m MockDictionary) lookup(word string) ?dictionary.Result {
	return anki.result
}

const result = dictionary.Result{
	word: 'word'
	dictionary: 'dictionary'
	web_url: 'https://example.com/test'
	entries: [
		dictionary.Entry{
			id: 'id'
			headword: 'headword'
			function_label: 'function_label'
			grammatical_note: 'grammatical_note'
			pronunciation: dictionary.Pronunciation{
				notation: 'IPA'
				accents: [
					dictionary.Accent{
						label: 'US'
						spelling: 'spelling'
					},
				].repeat(2)
			}
			inflections: [
				dictionary.Inflection{
					form_label: 'form_label'
					inflected_form: 'inflected_form'
					pronunciation: dictionary.Pronunciation{
						notation: 'IPA'
						accents: [
							dictionary.Accent{
								label: 'US'
								spelling: 'spelling'
							},
						].repeat(2)
					}
				},
			].repeat(2)
			definitions: [
				dictionary.Definition{
					grammatical_note: 'grammatical_note'
					sense: 'sense'
					examples: [
						'example sentence',
					].repeat(5)
				},
			]
		},
	].repeat(2)
}
