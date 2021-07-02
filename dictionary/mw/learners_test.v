module mw

import net.http
import os
import dictionary

fn test_lookup_request() {
	learners := new_learners('dummy key')
	req := learners.lookup_request('put up')

	assert req.method == http.Method.get
	assert req.url == 'https://www.dictionaryapi.com/api/v3/references/learners/json/put%20up?key=dummy+key'
}

fn test_web_url() {
	learners := new_learners('dummy key')
	url := learners.web_url('put up')

	assert url == 'https://learnersdictionary.com/definition/put%20up'
}

fn test_candidate() {
	entry := Entry{
		meta: Meta{
			stems: ['drop', 'drops', 'drop off']
		}
	}
	assert candidate('drop', entry) == true
	assert candidate('DROPS', entry) == true
	assert candidate('drop-off', entry) == false
}

fn test_to_dictionary_result() ? {
	{
		// basic
		learners := new_learners('dummy key')
		entries := parse_response(load('testdata/learners/test.json')) ?
		res := learners.to_dictionary_result('test', entries)

		assert res.word == 'test'
		assert res.dictionary == "Merriam-Webster's Learner's Dictionary"
		assert res.web_url == 'https://learnersdictionary.com/definition/test'
		assert res.entries.len == 2
		first := res.entries.first()
		assert first == dictionary.Entry{
			id: 'test:1'
			headword: 'test'
			function_label: 'noun'
			grammatical_note: 'count'
			pronunciation: dictionary.Pronunciation{
				notation: 'IPA'
				accents: [dictionary.Accent{
					label: ''
					spelling: 'ˈtɛst'
					audio: ''
				}]
			}
			inflections: [dictionary.Inflection{
				form_label: 'plural'
				inflected_form: 'tests'
				pronunciation: dictionary.Pronunciation{
					notation: 'IPA'
					accents: []
				}
			}]
			definitions: first.definitions
		}
		assert first.definitions.len == 6
		assert first.definitions[0] == dictionary.Definition{
			grammatical_note: ''
			sense: "{bc}a set of questions or problems that are designed to measure a person's knowledge, skills, or abilities. {dx}see also {dxt|intelligence test||} {dxt|rorschach test||} {dxt|screen test||}{/dx}"
			examples: ['She is studying for her math/spelling/history {it}test{/it}.',
				'I passed/failed/flunked my biology {it}test{/it}.',
				'The teacher sat at his desk grading {it}tests{/it}.',
				"a driver's/driving {it}test{/it} [=a test that is used to see if someone is able to safely drive a car]",
				'an IQ {it}test{/it}', '{it}test{/it} questions',
				'The {it}test{/it} will be on [=the questions on the test will be about] the first three chapters of the book.',
				'We {phrase}took/had a test{/phrase} on European capitals. = ({it}Brit{/it}) We {phrase}did a test{/phrase} on European capitals.',
				'The college relies on {phrase}test scores{/phrase} in its admissions process.',
			]
		}
	}
	{
		// Suggestions
		learners := new_learners('dummy key')
		suggestions := parse_response(load('testdata/learners/furnitura.json')) ?
		res := learners.to_dictionary_result('furnitura', suggestions)

		assert res == dictionary.Result{
			word: 'furnitura'
			dictionary: "Merriam-Webster's Learner's Dictionary"
			web_url: 'https://learnersdictionary.com/definition/furnitura'
			entries: []
			suggestion: ['furniture', 'forfeiture', 'Ventura', 'furious', 'furnish', 'furnished',
				'furnishes', 'furrier', 'furriers', 'ventura', 'barbiturate', 'forfeitures',
				'barbiturates', 'be natural', 'furnishing', 'tourniquet']
		}
	}
}

fn load(testfile string) string {
	return os.read_file('./dictionary/mw/$testfile') or { panic(err) }
}
