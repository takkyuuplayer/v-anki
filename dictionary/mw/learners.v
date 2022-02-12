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

pub fn (l Learners) lookup(condition dictionary.LookupCondition) ?dictionary.Result {
	req := l.lookup_request(condition.word)
	return l.to_dictionary_result(condition, parse_response((req.do() ?).text) ?)
}

pub fn (l Learners) lookup_request(word string) http.Request {
	url := 'https://www.dictionaryapi.com/api/v3/references/learners/json/' +
		urllib.path_escape(word) + '?key=' + urllib.query_escape(l.api_key)

	return http.Request{
		method: http.Method.get
		url: url
	}
}

pub fn (l Learners) to_dictionary_result(condition dictionary.LookupCondition, result Result) dictionary.Result {
	if result is []string {
		return dictionary.Result{
			word: condition.word
			dictionary: mw.dictionary_learners
			web_url: learners_web_url(condition.word)
			suggestion: result
		}
	}

	entries := result as []Entry
	dict_entries := entries.to_dictionary_result(condition, learners_web_url)
	headword := if dict_entries.len > 0 { dict_entries.first().headword } else { condition.word }

	return dictionary.Result{
		word: headword
		dictionary: mw.dictionary_learners
		web_url: learners_web_url(condition.word)
		entries: dict_entries
	}
}

pub fn learners_web_url(word string) string {
	return 'https://learnersdictionary.com/definition/' + urllib.path_escape(word)
}
