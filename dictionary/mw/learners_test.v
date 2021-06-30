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
