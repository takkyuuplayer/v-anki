module mw

import net.http
import net.urllib

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

pub fn (l Learners) web_url(word string) string {
	return 'https://learnersdictionary.com/definition/' + urllib.path_escape(word)
}

fn candidate(entry Entry, searhword string) bool {
	mut variants := map[string]bool{}
	variants[searhword] = true

	is_phrase := searhword.split(' ').len > 1
	if is_phrase {
		variants[searhword.replace(' ', '-')] = true
	}

	return entry.meta.stems.filter(it in variants).len > 0
}
