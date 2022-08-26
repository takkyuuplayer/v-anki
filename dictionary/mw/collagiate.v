module mw

import net.http
import net.urllib
import dictionary

const dictionary_collegiate = "Merriam-Webster's Collegiate Dictionary"

struct Collegiate {
	api_key string
}

pub fn new_collegiate(api_key string) Collegiate {
	return Collegiate{
		api_key: api_key
	}
}

pub fn (c Collegiate) lookup(condition dictionary.LookupCondition) ?dictionary.Result {
	req := c.lookup_request(condition.word)
	return c.to_dictionary_result(condition, parse_response((req.do()?).text)?)
}

pub fn (c Collegiate) lookup_request(word string) http.Request {
	url := 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/' +
		urllib.path_escape(word) + '?key=' + urllib.query_escape(c.api_key)

	return http.Request{
		method: http.Method.get
		url: url
	}
}

pub fn (c Collegiate) to_dictionary_result(condition dictionary.LookupCondition, result Result) dictionary.Result {
	if result is []string {
		return dictionary.Result{
			word: condition.word
			dictionary: mw.dictionary_collegiate
			web_url: collegiate_web_url(condition.word)
			suggestion: result
		}
	}

	entries := result as []Entry
	dict_entries := entries.to_dictionary_result(condition, collegiate_web_url)
	headword := if dict_entries.len > 0 { dict_entries.first().headword } else { condition.word }

	return dictionary.Result{
		word: headword
		dictionary: mw.dictionary_collegiate
		web_url: collegiate_web_url(condition.word)
		entries: dict_entries
	}
}

pub fn collegiate_web_url(word string) string {
	return 'https://www.merriam-webster.com/dictionary/' + urllib.path_escape(word)
}
