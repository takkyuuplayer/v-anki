module mw_test

import mw
import net.http
import os

fn test_lookup_request() {
	learners := mw.new_learners('dummy key')
	req := learners.lookup_request('put up')

	assert req.method == http.Method.get
	assert req.url == 'https://www.dictionaryapi.com/api/v3/references/learners/json/put%20up?key=dummy+key'
}

fn test_web_url() {
	learners := mw.new_learners('dummy key')
	url := learners.web_url('put up')

	assert url == 'https://learnersdictionary.com/definition/put%20up'
}
