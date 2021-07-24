module anki

import dictionary
import takkyuuplayer.streader
import takkyuuplayer.bytebuf

fn test_run() ? {
	{
		// basic
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{}
		mut reader := streader.new('test\n\ntest')
		mut writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_basic_card)
		runner.run(reader, writer)

		cards := to_basic_card(anki.result)
		line := cards[0].front + '\t' + cards[0].back.replace_each(['\r', ' ', '\n', ' '])

		assert writer.str() == [line + '\n'].repeat(cards.len * 2).join('')
	}
	{
		// sentences
		mut dictionaries := []dictionary.Dictionary{}
		dictionaries << MockDictionary{}
		mut reader := streader.new('test\n\ntest')
		mut writer := bytebuf.Buffer{}
		runner := new(dictionaries, to_sentences_card)
		runner.run(reader, writer)

		cards := to_sentences_card(anki.result)
		line := cards[0].front.replace_each(['\r', ' ', '\n', ' ']) + '\t' +
			cards[0].back.replace_each(['\r', ' ', '\n', ' '])

		assert writer.str() == [line + '\n'].repeat(cards.len * 2).join('')
	}
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
			].repeat(2)
		},
	].repeat(2)
}
