module mw

import net.http
import os
import dictionary

fn test_collegiate_lookup_request() {
	collegiate := new_collegiate('dummy key')
	req := collegiate.lookup_request('put up')

	assert req.method == http.Method.get
	assert req.url == 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/put%20up?key=dummy+key'
}

fn test_collegiate_web_url() {
	url := collegiate_web_url('put up')

	assert url == 'https://www.merriam-webster.com/dictionary/put%20up'
}

fn test_to_dictionary_result() ? {
	{
		// basic
		collegiate := new_collegiate('dummy key')
		entries := parse_response(load('testdata/collegiate/test.json'))?
		res := collegiate.to_dictionary_result(dictionary.LookupCondition{ word: 'test' },
			entries)

		assert res.word == 'test'
		assert res.dictionary == "Merriam-Webster's Collegiate Dictionary"
		assert res.web_url == 'https://www.merriam-webster.com/dictionary/test'
		assert res.entries.len == 6
	}
	{
		// phrasal verb
		collegiate := new_collegiate('dummy key')
		entries := parse_response(load('testdata/collegiate/drop_off.json'))?
		res := collegiate.to_dictionary_result(dictionary.LookupCondition{ word: 'drop off' },
			entries)

		assert res.word == 'drop off'
		assert res.dictionary == "Merriam-Webster's Collegiate Dictionary"
		assert res.entries.len == 1

		res2 := collegiate.to_dictionary_result(dictionary.LookupCondition{ word: 'dropping off' },
			entries)
		assert res2.word == 'drop off'
		assert res2.entries.len == 1
	}
}

fn load(testfile string) string {
	return os.read_file('./dictionary/mw/$testfile') or { panic(err) }
}
