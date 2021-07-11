module anki

import dictionary

fn test_to_basic_card() ? {
	result := dictionary.Result{
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
						dictionary.Accent{
							label: 'UK'
							spelling: 'spelling'
						},
					]
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
								dictionary.Accent{
									label: 'UK'
									spelling: 'spelling'
								},
							]
						}
					},
				]
				definitions: [
					dictionary.Definition{
						grammatical_note: 'grammatical_note'
						sense: 'sense'
						examples: [
							'example sentence 1',
							'example sentence 2',
						]
					},
				]
			},
		]
	}

	card := to_basic_card(result) ?
	assert card[0].front == 'word'
	assert card[0].back.len > 0

	//dump(card[0].back)
	//assert false
}
