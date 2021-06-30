module mw

import net.http
import net.urllib
import dictionary

const dictionary_learners = "Merriam-Webster's Learner's Dictionary"

struct Learners {
	api_key string
}

pub fn new_learners(api_key string) Learners {
	return Learners{
		api_key: api_key
	}
}

pub fn (l Learners) lookup_request(word string) http.Request {
	url := 'https://www.dictionaryapi.com/api/v3/references/learners/json/' +
		urllib.path_escape(word) + '?key=' + urllib.query_escape(l.api_key)

	return http.Request{
		method: http.Method.get
		url: url
	}
}

pub fn (l Learners) to_dictionary_result(word string, result Result) dictionary.Result {
	if result is []string {
		return dictionary.Result{
			word: word
			dictionary: mw.dictionary_learners
			web_url: l.web_url(word)
			suggestion: result
		}
	}

	return dictionary.Result{
		word: word
		dictionary: mw.dictionary_learners
		web_url: l.web_url(word)
	}
}

pub fn (l Learners) web_url(word string) string {
	return 'https://learnersdictionary.com/definition/' + urllib.path_escape(word)
}

fn candidate(word string, entry Entry) bool {
	return word.to_lower() in entry.meta.stems
}
