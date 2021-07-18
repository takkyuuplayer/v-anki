module anki

import dictionary

fn test_to_basic_card() {
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
					variants: [
						dictionary.Variant{
							label: 'variant_label'
							variant: 'variant'
						},
					].repeat(2)
				},
			].repeat(2)
		}

		cards := to_basic_card(result)
		assert cards[0].front == 'word'
		assert cards[0].back.len > 0
		// dump(card[0].back)
		// assert false
	}
	{
		// empty
		result := dictionary.Result{
			word: 'word'
			dictionary: 'dictionary'
			web_url: 'https://example.com/test'
		}
		cards := to_basic_card(result)

		assert cards.len == 0
	}
}
