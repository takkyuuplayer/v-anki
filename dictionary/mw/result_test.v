module mw

import dictionary.mw
import os
import dictionary

fn test_parse_response() ? {
	{
		// basic
		res := mw.parse_response(load('testdata/learners/test.json')) ?

		assert res is []Entry

		entries := res as []Entry

		assert entries.len == 10

		first := entries[0]
		assert first.meta.id == 'test:1'
		assert first.meta.uuid == '050b619c-ffad-4eaf-ba0a-93e9dab0e278'
		assert first.meta.src == 'learners'
		assert first.meta.section == 'alpha'
		assert first.meta.target.tuuid == ''
		assert first.meta.target.tsrc == ''
		assert first.meta.highlight == 'yes'
		assert first.meta.stems.len == 22
		assert first.meta.stems[0] == 'test'
		assert first.meta.offensive == false
		assert first.meta.app_shortdef.hw == 'test:1'
		assert first.meta.app_shortdef.fl == 'noun'
		assert first.meta.app_shortdef.def.len == 3
		assert first.meta.app_shortdef.def[0] == "{bc} a set of questions or problems that are designed to measure a person's knowledge, skills, or abilities"
		assert first.hwi.hw == 'test'
		assert first.hwi.prs.len == 1
		assert first.hwi.prs[0].ipa == 'ˈtɛst'
		assert first.hwi.prs[0].sound.audio == 'test0001'
		assert first.hom == 1
		assert first.fl == 'noun'
		assert first.lbs.len == 0
		assert first.ins.len == 1
		assert first.ins[0].inf == 'tests'
		assert first.ins[0].il == 'plural'
		assert first.gram == 'count'
		assert first.def.len == 1
		assert first.def[0].sls.len == 0
		assert first.def[0].sseq.len == 6
		assert first.def[0].sseq[0].sn == '1'
		assert first.def[0].sseq[0].dt.text == "{bc}a set of questions or problems that are designed to measure a person's knowledge, skills, or abilities. {dx}see also {dxt|intelligence test||} {dxt|rorschach test||} {dxt|screen test||}{/dx}"
		assert first.def[0].sseq[0].dt.vis.len == 9
		assert first.def[0].sseq[0].dt.vis.len == 9
		assert first.def[0].sseq[3].dt.uns.len == 1
		assert first.def[0].sseq[3].dt.uns[0].text == 'often used before another noun'

		assert entries[1].hom == 2
		assert entries[1].fl == 'verb'
		assert entries[1].hwi.prs.len == 1
	}
	{
		// with vrs
		res := mw.parse_response(load('testdata/learners/amortize.json')) ?
		entries := res as []Entry

		assert entries.len == 1
		assert entries[0].vrs == [
			mw.Vr{
				vl: 'also British'
				va: 'am*or*tise'
				prs: [
					mw.Pr{
						ipa: 'ˈæmɚˌtaɪz'
						mw: ''
						l: ''
						sound: mw.Sound{
							audio: 'amorti02'
						}
						pun: ','
					},
					mw.Pr{
						ipa: 'əˈmɔːˌtaɪz'
						mw: ''
						l: 'British'
						sound: mw.Sound{
							audio: ''
						}
					},
				]
			},
		]
	}
	{
		// example sentense with wsgram
		res := mw.parse_response(load('testdata/learners/hemorrhage.json')) ?
		entries := res as []Entry

		assert entries.len == 2

		entry := entries[0]

		assert entry.def[0].sseq[0].dt.vis == [
			'[count] The patient suffered a cerebral {it}hemorrhage{/it}.',
			'[noncount] There is a possibility of {it}hemorrhage{/it} with the procedure.',
		]
	}
	{
		// entry in uros
		res := mw.parse_response(load('testdata/learners/accountability.json')) ?
		entries := res as []Entry

		assert entries.len == 1

		entry := entries[0]

		assert entry.uros.len == 1
		assert entry.uros[0].ure == 'ac*count*abil*i*ty'
		assert entry.uros[0].prs.len == 1
		assert entry.uros[0].fl == 'noun'
		assert entry.uros[0].ins.len == 0
		assert entry.uros[0].utxt.vis.len == 2
		assert entry.uros[0].gram == 'noncount'
	}
	{
		// no def section
		res := mw.parse_response(load('testdata/learners/deathbed.json')) ?
		entries := res as []Entry

		assert entries.len == 1
		assert entries[0].def.len == 0
		assert entries[0].uros.len == 1
		assert entries[0].uros[0].lbs == ['always used before a noun']
		assert entries[0].dros[0].def[0].sseq[0].dt.uns[0].text == 'often used figuratively to say that someone is very close to dying or very sick'
	}
	{
		// meta.app_shortdef.def is not an object
		res := mw.parse_response(load('testdata/learners/junk.json')) ?
		entries := res as []Entry

		assert entries.len == 8
		assert entries[4].meta.app_shortdef.def.len == 0

		assert entries[7].def[0].sseq[0].sgram == 'count'
	}
	{
		// lbs in sense
		res := mw.parse_response(load('testdata/learners/sheer.json')) ?
		entries := res as []Entry

		assert entries.len == 3
		assert entries[0].def[0].sseq[0].lbs == ['always used before a noun']
	}
	{
		// phrasal verb
		res := mw.parse_response(load('testdata/learners/drop_off.json')) ?
		entries := res as []Entry

		assert entries.len == 2

		last := entries[1]

		assert last.dros.len == 12
		assert last.dros.filter(it.drp == 'drop off').len == 1
	}
	{
		// when not found
		res := mw.parse_response(load('testdata/learners/abcabcabcabc.json')) ?

		assert res is []string

		suggestions := res as []string

		assert suggestions.len == 0
	}
	{
		// when suggested
		res := mw.parse_response(load('testdata/learners/furnitura.json')) ?

		assert res is []string

		suggestions := res as []string

		assert suggestions.len == 16
		assert suggestions[0] == 'furniture'
	}
	{
		// collegiate
		res := mw.parse_response(load('testdata/collegiate/test.json')) ?

		assert res is []Entry

		entries := res as []Entry

		assert entries.len == 10

		first := entries[0]
		assert first.hwi == mw.Hwi{
			hw: 'test'
			prs: [
				mw.Pr{
					mw: 'ˈtest'
					sound: mw.Sound{
						audio: 'test0001'
					}
				},
			]
		}
		assert first.def[0].sseq.len == 9
		assert first.def[0].sseq[3] == mw.Sense{
			sn: '2 a (1)'
			dt: mw.DefinitionText{
				text: '{bc}a critical examination, observation, or evaluation {bc}{sx|trial||}'
			}
			sdsense: mw.Sdsense{
				sd: 'specifically'
				dt: mw.DefinitionText{
					text: '{bc}the procedure of submitting a statement to such conditions or operations as will lead to its proof or disproof or to its acceptance or rejection'
					vis: ['a {wi}test{/wi} of a statistical hypothesis']
				}
			}
		}
	}
}

fn test_to_dictionary_result() ? {
	{
		// basic
		result := parse_response(load('testdata/learners/test.json')) ? as []Entry
		entries := result.to_dictionary_result('test', learners_web_url)
		assert entries.len == 3
		first := entries.first()
		assert first == dictionary.Entry{
			id: 'test:1'
			headword: 'test'
			function_label: 'noun'
			grammatical_note: 'count'
			pronunciation: dictionary.Pronunciation{
				notation: 'IPA'
				accents: [dictionary.Accent{
					spelling: 'ˈtɛst'
				}]
			}
			inflections: [
				dictionary.Inflection{
					form_label: 'plural'
					inflected_form: 'tests'
				},
			]
			definitions: first.definitions
		}
		assert first.definitions.len == 6
		assert first.definitions[0] == dictionary.Definition{
			grammatical_note: ''
			sense: '<b>:</b> a set of questions or problems that are designed to measure a person\'s knowledge, skills, or abilities. &mdash; see also <a target="_blank" href="https://learnersdictionary.com/definition/intelligence%20test">intelligence test</a> <a target="_blank" href="https://learnersdictionary.com/definition/rorschach%20test">rorschach test</a> <a target="_blank" href="https://learnersdictionary.com/definition/screen%20test">screen test</a>'
			examples: ['She is studying for her math/spelling/history <i>test</i>.',
				'I passed/failed/flunked my biology <i>test</i>.',
				'The teacher sat at his desk grading <i>tests</i>.',
				"a driver's/driving <i>test</i> [=a test that is used to see if someone is able to safely drive a car]",
				'an IQ <i>test</i>', '<i>test</i> questions',
				'The <i>test</i> will be on [=the questions on the test will be about] the first three chapters of the book.',
				'We <b><i>took/had a test</i></b> on European capitals. = (<i>Brit</i>) We <b><i>did a test</i></b> on European capitals.',
				'The college relies on <b><i>test scores</i></b> in its admissions process.']
		}

		second := entries[1]
		assert second.inflections == [
			dictionary.Inflection{
				form_label: ''
				inflected_form: 'tests'
				pronunciation: dictionary.Pronunciation{
					notation: ''
					accents: []
				}
			},
			dictionary.Inflection{
				form_label: ''
				inflected_form: 'tested'
				pronunciation: dictionary.Pronunciation{
					notation: ''
					accents: []
				}
			},
			dictionary.Inflection{
				form_label: ''
				inflected_form: 'testing'
				pronunciation: dictionary.Pronunciation{
					notation: ''
					accents: []
				}
			},
		]
	}
	{
		result := parse_response(load('testdata/learners/sheer.json')) ? as []Entry
		entries := result.to_dictionary_result('sheer', learners_web_url)

		assert entries[0].definitions[0].sense == '<i>always used before a noun</i>  &mdash; used to emphasize the large amount, size, or degree of something'
	}
	{
		// uros
		result := parse_response(load('testdata/learners/accountability.json')) ? as []Entry
		entries := result.to_dictionary_result('accountability', learners_web_url)

		assert entries.len == 2
		assert entries[1] == dictionary.Entry{
			id: 'accountable-ac*count*abil*i*ty'
			headword: 'accountability'
			function_label: 'noun'
			grammatical_note: 'noncount'
			pronunciation: dictionary.Pronunciation{
				notation: 'IPA'
				accents: [dictionary.Accent{
					spelling: 'əˌkæʊntəˈbɪləti'
				}]
			}
			inflections: []
			definitions: [
				dictionary.Definition{
					examples: [
						'We now have greater <i>accountability</i> in the department. [=people in the department can now be held more responsible for what happens]',
						'corporate <i>accountability</i>',
					]
				},
			]
		}
	}
	{
		// dros
		result := parse_response(load('testdata/learners/drop_off.json')) ? as []Entry
		entries := result.to_dictionary_result('drop off', learners_web_url)

		assert entries.len == 1
		assert entries == [
			dictionary.Entry{
				id: 'drop:2-drop off'
				headword: 'drop off'
				function_label: 'phrasal verb'
				grammatical_note: ''
				pronunciation: dictionary.Pronunciation{
					notation: ''
				}
				definitions: [
					dictionary.Definition{
						grammatical_note: ''
						sense: '<b>:</b> to decrease in amount'
						examples: [
							'After the holidays, business usually <i>drops off</i>.',
						]
					},
					dictionary.Definition{
						grammatical_note: ''
						sense: '<b>:</b> to fall asleep. &mdash; see also <a target="_blank" href="https://learnersdictionary.com/definition/drop">drop</a>'
						examples: [
							'The baby tends to <i>drop off</i> after he eats.',
							'She lay down and <b><i>dropped off to sleep</i></b>.',
						]
					},
				]
			},
		]
	}
	{
		// dros: verge on/upon
		result := parse_response(load('testdata/learners/verge_on.json')) ? as []Entry
		entries := result.to_dictionary_result('verge on', learners_web_url)

		assert entries.len == 1
		assert entries == [
			dictionary.Entry{
				id: 'verge:2-verge on/upon'
				headword: 'verge on/upon'
				function_label: 'phrasal verb'
				grammatical_note: ''
				pronunciation: dictionary.Pronunciation{
					notation: ''
					accents: []
				}
				inflections: []
				definitions: [
					dictionary.Definition{
						grammatical_note: ''
						sense: '<b>:</b> to come near to being (something)'
						examples: [
							'comedy that <i>verges on</i> farce [=comedy that is almost farce]',
							'His accusations were <i>verging on</i> slander.',
						]
					},
				]
				variants: []
			},
		]
	}
	{
		// lbs in dros to grammatical_note
		result := parse_response(load('testdata/learners/deathbed.json')) ? as []Entry
		entries := result.to_dictionary_result('deathbed', learners_web_url)

		entries[1].grammatical_note == '<i>always used before a noun</i>.'
	}
	{
		// Pronunciation in vrs
		result := parse_response(load('testdata/learners/amortize.json')) ? as []Entry
		entries := result.to_dictionary_result('amortize', learners_web_url)

		assert entries.len == 2
		assert entries[0].pronunciation == dictionary.Pronunciation{
			notation: 'IPA'
			accents: [
				dictionary.Accent{
					label: ''
					spelling: 'ˈæmɚˌtaɪz'
					audio: ''
				},
				dictionary.Accent{
					label: 'British'
					spelling: 'əˈmɔːˌtaɪz'
					audio: ''
				},
			]
		}
	}
}

fn test_candidate() {
	entry := mw.Entry{
		meta: mw.Meta{
			stems: ['drop', 'drops', 'drop off']
		}
	}
	assert candidate('drop', entry) == true
	assert candidate('DROPS', entry) == true
	assert candidate('drop-off', entry) == false
}

fn test_match_phrasal_verb() {
	{
		assert match_phrasal_verb('drop off', 'drop off')
		assert !match_phrasal_verb('drop on', 'drop off')
	}
	{
		assert match_phrasal_verb('verge on', 'verge on/upon')
		assert match_phrasal_verb('verge upon', 'verge on/upon')
	}
	{
		assert !match_phrasal_verb('put up', 'put up with')
		assert !match_phrasal_verb('put up with', 'put up')
	}
}

fn load(testfile string) string {
	return os.read_file('./dictionary/mw/$testfile') or { panic(err) }
}
