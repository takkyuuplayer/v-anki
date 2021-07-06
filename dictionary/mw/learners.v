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

pub fn to_dictionary_result(word string, result Result) dictionary.Result {
	if result is []string {
		return dictionary.Result{
			word: word
			dictionary: mw.dictionary_learners
			web_url: web_url(word)
			suggestion: result
		}
	}

	mut dict_entries := []dictionary.Entry{}
	is_phrase := word.split(' ').len > 1
	for entry in result as []Entry {
		if !candidate(word, entry) {
			continue
		}
		// base_word := entry.meta.app_shortdef.hw.split(':')[0]
		if !is_phrase {
			{
				dict_entries << dictionary.Entry{
					id: entry.meta.id
					headword: entry.hwi.hw.replace('*', '')
					function_label: entry.fl
					grammatical_note: entry.gram
					pronunciation: entry.hwi.prs.to_dictionary_result()
					inflections: entry.ins.to_dictionary_result()
					definitions: entry.def.to_dictionary_result()
				}
			}
			for uro in entry.uros {
				dict_entries << dictionary.Entry{
					id: '$entry.meta.id-$uro.ure'
					headword: uro.ure.replace('*', '')
					function_label: uro.fl
					grammatical_note: uro.gram
					pronunciation: uro.prs.to_dictionary_result()
					inflections: uro.ins.to_dictionary_result()
					definitions: [dictionary.Definition{
						examples: uro.utxt.vis.map(to_html(it))
					}]
				}
			}
		}
		for dro in entry.dros {
			if dro.drp != word {
				continue
			}
			dict_entries << dictionary.Entry{
				id: '$entry.meta.id-$dro.drp'
				headword: dro.drp
				function_label: dro.gram
				definitions: dro.def.to_dictionary_result()
			}
		}
	}

	headword := if dict_entries.len > 0 { dict_entries.first().headword } else { word }

	return dictionary.Result{
		word: headword
		dictionary: mw.dictionary_learners
		web_url: web_url(word)
		entries: dict_entries
	}
}

pub fn web_url(word string) string {
	return 'https://learnersdictionary.com/definition/' + urllib.path_escape(word)
}

fn candidate(word string, entry Entry) bool {
	return word.to_lower() in entry.meta.stems
}

const tag_map = map{
	'bc':      '<b>:</b> '
	'b':       '<b>'
	'/b':      '</b>'
	'inf':     '<sub>'
	'/inf':    '</sub>'
	'it':      '<i>'
	'/it':     '</i>'
	'ldquo':   '&ldquo;'
	'rdquo':   '&rdquo;'
	'sc':      '<span style="font-variant: small-caps;">'
	'/sc':     '</span>'
	'sup':     '</sup>'
	'phrase':  '<b><i>'
	'/phrase': '</i></b>'
	'qword':   '<i>'
	'/qword':  '</i>'
	'wi':      '<i>'
	'/wi':     '</i>'
	'parahw':  '<span style="font-variant: small-caps;">'
	'/parahw': '</span>'
	'gloss':   '&lsqb;'
	'/gloss':  '&rsqb;'
	'dx':      '&mdash; '
	'/dx':     ''
	'dx_ety':  '&mdash; '
	'/dx_ety': ''
	'ma':      '&mdash; more at '
	'dx_def':  '('
	'/dx_def': ')'
}

fn to_html(sentence string) string {
	mut before, mut after := sentence.before('{'), sentence.all_after('{')
	mut res := ''

	for before != after {
		res += before

		tag := after.before('}')
		after = after.all_after('}')
		if tag in mw.tag_map {
			res += mw.tag_map[tag]
		} else if tag.contains('|') {
			segments := tag.split('|')
			link_word := segments[1].split(':')[0]
			res += '<a target="_blank" href="${web_url(link_word)}">$link_word</a>'
		} else {
			eprintln('unknown tag in sentence: $tag')
		}
		before, after = after.before('{'), after.all_after('{')
	}
	res += before

	return res
}
