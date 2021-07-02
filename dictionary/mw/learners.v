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

	mut dict_entries := []dictionary.Entry{}
	is_phrase := word.split(' ').len > 1
	for entry in result as []Entry {
		if !candidate(word, entry) {
			continue
		}
		// base_word := entry.meta.app_shortdef.hw.split(':')[0]
		if !is_phrase {
			{
				mut definitions := []dictionary.Definition{}
				for def in entry.def {
					for sense in def.sseq {
						definitions << dictionary.Definition{
							grammatical_note: sense.sgram
							sense: sense.dt.text
							examples: sense.dt.vis
						}
					}
				}
				dict_entries << dictionary.Entry{
					id: entry.meta.id
					headword: entry.hwi.hw
					function_label: entry.fl
					grammatical_note: entry.gram
					pronunciation: dictionary.Pronunciation{
						notation: 'IPA'
						accents: entry.hwi.prs.map(fn (pr Pr) dictionary.Accent {
							return dictionary.Accent{
								label: pr.l
								spelling: pr.ipa
							}
						})
					}
					inflections: entry.ins.map(fn (inf Inf) dictionary.Inflection {
						return dictionary.Inflection{
							form_label: inf.il
							inflected_form: inf.inf
							pronunciation: dictionary.Pronunciation{
								notation: 'IPA'
								accents: inf.prs.map(fn (pr Pr) dictionary.Accent {
									return dictionary.Accent{
										label: pr.l
										spelling: pr.ipa
									}
								})
							}
						}
					})
					definitions: definitions
				}
			}
			for uro in entry.uros {
				mut definitions := []dictionary.Definition{}
				definitions << dictionary.Definition{
					examples: uro.utxt.vis
				}
				dict_entries << dictionary.Entry{
					id: '$entry.meta.id-$uro.ure'
					headword: uro.ure
					function_label: uro.fl
					grammatical_note: uro.gram
					pronunciation: dictionary.Pronunciation{
						notation: 'IPA'
						accents: uro.prs.map(fn (pr Pr) dictionary.Accent {
							return dictionary.Accent{
								label: pr.l
								spelling: pr.ipa
							}
						})
					}
					inflections: uro.ins.map(fn (inf Inf) dictionary.Inflection {
						return dictionary.Inflection{
							form_label: inf.il
							inflected_form: inf.inf
							pronunciation: dictionary.Pronunciation{
								notation: 'IPA'
								accents: inf.prs.map(fn (pr Pr) dictionary.Accent {
									return dictionary.Accent{
										label: pr.l
										spelling: pr.ipa
									}
								})
							}
						}
					})
					definitions: definitions
				}
			}
		}
	}

	headword := if dict_entries.len > 0 { dict_entries.first().headword } else { word }

	return dictionary.Result{
		word: headword
		dictionary: mw.dictionary_learners
		web_url: l.web_url(word)
		entries: dict_entries
	}
}

pub fn (l Learners) web_url(word string) string {
	return 'https://learnersdictionary.com/definition/' + urllib.path_escape(word)
}

fn candidate(word string, entry Entry) bool {
	return word.to_lower() in entry.meta.stems
}
