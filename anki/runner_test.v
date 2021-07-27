module anki

import dictionary
import takkyuuplayer.streader
import takkyuuplayer.bytebuf

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
		line := cards[0].front + '\t' + cards[0].back.replace_each(['\r', ' ', '\n', ' '])

		assert writer.str() == [line + '\n'].repeat(cards.len * 2).join('')
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
		line := cards[0].front.replace_each(['\r', ' ', '\n', ' ']) + '\t' +
			cards[0].back.replace_each(['\r', ' ', '\n', ' '])

		assert writer.str() == [line + '\n'].repeat(cards.len * 2).join('')
		assert err_writer.str() == ''
	}
	{
		// no entries
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{dictionary.Result{}}
		mut reader := streader.new('test\n\ntest')
		mut writer := bytebuf.Buffer{}
		mut err_writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_basic_card)
		runner.run(reader, writer, err_writer)

		assert writer.str() == ''
		line := 'NotFound\ttest'
		assert err_writer.str() == [line + '\n'].repeat(2).join('')
	}
}

struct MockDictionary {
	result dictionary.Result
}

fn (m MockDictionary) lookup(word string) ?dictionary.Result {
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
