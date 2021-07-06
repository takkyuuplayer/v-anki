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

fn test_learners_web_url() {
	url := learners_web_url('put up')

	assert url == 'https://learnersdictionary.com/definition/put%20up'
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
		assert res.entries.len == 3
	}
	{
		// uros
		learners := new_learners('dummy key')
		entries := parse_response(load('testdata/learners/accountability.json')) ?
		res := learners.to_dictionary_result('accountability', entries)

		assert res.word == 'accountable'
		assert res.entries.len == 2
	}
	{
		// dros
		learners := new_learners('dummy key')
		entries := parse_response(load('testdata/learners/drop_off.json')) ?
		res := learners.to_dictionary_result('drop off', entries)

		assert res.word == 'drop off'
		assert res.entries.len == 1
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
