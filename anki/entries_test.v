module anki

import dictionary

fn test_to_entries_card() {
	{
		// basic
		result := dictionary.Result{
			word: 'word'
			dictionary: 'dictionary'
			web_url: 'https://example.com/test'
			entries: [
				dictionary.Entry{
					id: 'id'
					headword: 'headword'
					function_label: 'function_label'
				},
				dictionary.Entry{
					id: 'id'
					headword: 'headword2'
					function_label: 'function_label'
				},
			]
		}

		cards := to_entries_card(result)
		assert cards.len == 2
		assert cards[0].front == 'headword'
		assert cards[1].front == 'headword2'
	}
	{
		// empty
		result := dictionary.Result{
			word: 'word'
			dictionary: 'dictionary'
			web_url: 'https://example.com/test'
		}
		cards := to_sentences_card(result)

		assert cards.len == 0
	}
}
