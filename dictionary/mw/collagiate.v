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

pub fn (c Collegiate) lookup_request(word string) http.Request {
	url := 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/' +
		urllib.path_escape(word) + '?key=' + urllib.query_escape(c.api_key)

	return http.Request{
		method: http.Method.get
		url: url
	}
}

pub fn (c Collegiate) to_dictionary_result(word string, result Result) dictionary.Result {
	if result is []string {
		return dictionary.Result{
			word: word
			dictionary: mw.dictionary_collegiate
			web_url: collegiate_web_url(word)
			suggestion: result
		}
	}

	entries := result as []Entry
	dict_entries := entries.to_dictionary_result(word, collegiate_web_url)
	headword := if dict_entries.len > 0 { dict_entries.first().headword } else { word }

	return dictionary.Result{
		word: headword
		dictionary: mw.dictionary_collegiate
		web_url: collegiate_web_url(word)
		entries: dict_entries
	}
}

pub fn collegiate_web_url(word string) string {
	return 'https://www.merriam-webster.com/dictionary/' + urllib.path_escape(word)
}
