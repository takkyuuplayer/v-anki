module anki

import dictionary
import takkyuuplayer.streader
import takkyuuplayer.bytebuf
import encoding.csv

fn test_run() ? {
	{
		// basic
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{anki.result}
		mut reader := streader.new('test\n\ntest')
		mut writer := bytebuf.Buffer{}
		mut err_writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_basic_card)
		runner.run(reader, writer, err_writer)

		cards := to_basic_card(anki.result)

		mut csv_writer := csv.new_writer()
		csv_writer.delimiter = `\t`
		fields := [cards[0].front, cards[0].back.replace_each(['\r', ' ', '\n', ' '])]
		for i := 0; i < 2; i++ { // 2 tests
			csv_writer.write(fields) or {}
		}

		assert writer.str() == csv_writer.str()
		assert err_writer.str() == ''
	}
	{
		// sentences
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{anki.result}
		mut reader := streader.new('test\n\ntest')
		mut writer := bytebuf.Buffer{}
		mut err_writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_sentences_card)
		runner.run(reader, writer, err_writer)

		cards := to_sentences_card(anki.result)
		fields := [
			cards[0].front.replace_each(['\r', ' ', '\n', ' ']),
			cards[0].back.replace_each(['\r', ' ', '\n', ' ']),
		]
		mut csv_writer := csv.new_writer()
		csv_writer.delimiter = `\t`
		for i := 0; i < 2 * 2 * 2; i++ { // 2 tests * 2 entries * 2 definitions
			csv_writer.write(fields) or {}
		}

		assert writer.str() == csv_writer.str()
		assert err_writer.str() == ''
	}
	{
		// no entries
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{dictionary.Result{}}
		mut reader := streader.new('test\n\napple')
		mut writer := bytebuf.Buffer{}
		mut err_writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_basic_card)
		runner.run(reader, writer, err_writer)

		assert writer.str() == ''
		assert err_writer.str() == 'NotFound\ttest\nNotFound\tapple\n'
	}
}

struct MockDictionary {
	result dictionary.Result
}

fn (m MockDictionary) lookup(condition dictionary.LookupCondition) ?dictionary.Result {
	return m.result
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
			].repeat(2)
		},
	].repeat(2)
}
