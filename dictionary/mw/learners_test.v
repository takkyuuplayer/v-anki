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
	url := web_url('put up')

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
		entries := parse_response(load('testdata/learners/test.json')) ?
		res := to_dictionary_result('test', entries)

		assert res.word == 'test'
		assert res.dictionary == "Merriam-Webster's Learner's Dictionary"
		assert res.web_url == 'https://learnersdictionary.com/definition/test'
		assert res.entries.len == 3
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
			sense: '<b>:</b> a set of questions or problems that are designed to measure a person\'s knowledge, skills, or abilities. &mdash; see also <a target="_blank" href="https://learnersdictionary.com/definition/intelligence%20test">intelligence test</a> <a target="_blank" href="https://learnersdictionary.com/definition/rorschach%20test">rorschach test</a> <a target="_blank" href="https://learnersdictionary.com/definition/screen%20test">screen test</a>'
			examples: ['She is studying for her math/spelling/history <i>test</i>.',
				'I passed/failed/flunked my biology <i>test</i>.',
				'The teacher sat at his desk grading <i>tests</i>.',
				"a driver's/driving <i>test</i> [=a test that is used to see if someone is able to safely drive a car]",
				'an IQ <i>test</i>', '<i>test</i> questions',
				'The <i>test</i> will be on [=the questions on the test will be about] the first three chapters of the book.',
				'We <b><i>took/had a test</i></b> on European capitals. = (<i>Brit</i>) We <b><i>did a test</i></b> on European capitals.',
				'The college relies on <b><i>test scores</i></b> in its admissions process.',
			]
		}
	}
	{
		// uros
		entries := parse_response(load('testdata/learners/accountability.json')) ?
		res := to_dictionary_result('accountability', entries)

		assert res.word == 'accountable'
		assert res.entries.len == 2
		assert res.entries[1] == dictionary.Entry{
			id: 'accountable-ac*count*abil*i*ty'
			headword: 'accountability'
			function_label: 'noun'
			grammatical_note: 'noncount'
			pronunciation: dictionary.Pronunciation{
				notation: 'IPA'
				accents: [dictionary.Accent{
					label: ''
					spelling: 'əˌkæʊntəˈbɪləti'
					audio: ''
				}]
			}
			inflections: []
			definitions: [dictionary.Definition{
				grammatical_note: ''
				sense: ''
				examples: [
					'We now have greater <i>accountability</i> in the department. [=people in the department can now be held more responsible for what happens]',
					'corporate <i>accountability</i>',
				]
			}]
		}
	}
	{
		// dros
		entries := parse_response(load('testdata/learners/drop_off.json')) ?
		res := to_dictionary_result('drop off', entries)

		assert res.word == 'drop off'
		assert res.entries.len == 1
		assert res.entries == [dictionary.Entry{
			id: 'drop:2-drop off'
			headword: 'drop off'
			function_label: 'phrasal verb'
			grammatical_note: ''
			pronunciation: dictionary.Pronunciation{
				notation: ''
				accents: []
			}
			inflections: []
			definitions: [dictionary.Definition{
				grammatical_note: ''
				sense: '<b>:</b> to decrease in amount'
				examples: ['After the holidays, business usually <i>drops off</i>.']
			}, dictionary.Definition{
				grammatical_note: ''
				sense: '<b>:</b> to fall asleep. &mdash; see also <a target="_blank" href="https://learnersdictionary.com/definition/drop">drop</a>'
				examples: ['The baby tends to <i>drop off</i> after he eats.',
					'She lay down and <b><i>dropped off to sleep</i></b>.',
				]
			}]
		}]
	}
	{
		// Suggestions
		suggestions := parse_response(load('testdata/learners/furnitura.json')) ?
		res := to_dictionary_result('furnitura', suggestions)

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
