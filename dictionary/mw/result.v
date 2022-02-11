// https://dictionaryapi.com/products/json
module mw

import x.json2
import dictionary

type Result = []Entry | []string

pub fn parse_response(body string) ?Result {
	raw_entries := json2.raw_decode(body) ?

	arr := raw_entries.arr()

	if arr.len == 0 {
		return Result([]string{})
	}

	if 'meta' !in arr[0].as_map() {
		return Result(arr.map(it.str()))
	}

	mut entries := []Entry{}
	for _, entry in arr {
		mut e := Entry{}
		e.from_json(entry)
		entries << e
	}

	return entries
}

struct Entry {
pub mut:
	meta     Meta
	hwi      Hwi
	vrs      []Vr
	hom      int
	fl       string
	lbs      []string
	ins      []Inf
	gram     string
	def      []DefinitionSection
	uros     []Uro
	dros     []Dro
	dxnls    []string
	shortdef []string
}

fn (mut e Entry) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'meta' {
				e.meta.from_json(v)
			}
			'hwi' {
				e.hwi.from_json(v)
			}
			'hom' {
				e.hom = v.int()
			}
			'fl' {
				e.fl = v.str()
			}
			'lbs' {
				e.lbs = v.arr().map(it.str())
			}
			'ins' {
				e.ins = v.arr().map(fn (item json2.Any) Inf {
					mut i := Inf{}
					i.from_json(item)
					return i
				})
			}
			'gram' {
				e.gram = v.str()
			}
			'def' {
				e.def = v.arr().map(fn (item json2.Any) DefinitionSection {
					mut d := DefinitionSection{}
					d.from_json(item)
					return d
				})
			}
			'uros' {
				e.uros = v.arr().map(fn (item json2.Any) Uro {
					mut u := Uro{}
					u.from_json(item)
					return u
				})
			}
			'dros' {
				e.dros = v.arr().map(fn (item json2.Any) Dro {
					mut d := Dro{}
					d.from_json(item)
					return d
				})
			}
			'vrs' {
				e.vrs = v.arr().map(fn (item json2.Any) Vr {
					mut v := Vr{}
					v.from_json(item)
					return v
				})
			}
			'shortdef' {
				e.shortdef = v.arr().map(it.str())
			}
			'dxnls' {
				e.dxnls = v.arr().map(it.str())
			}
			else {
				eprintln('unknown key in Entry: $k')
			}
		}
	}
}

pub fn (entries []Entry) to_dictionary_result(condition dictionary.LookupCondition, web_url fn (string) string) []dictionary.Entry {
	mut dict_entries := []dictionary.Entry{}
	is_phrase := condition.word.split(' ').len > 1
	for entry in entries {
		if !candidate(condition.word, entry) {
			continue
		}
		baseword := normalize(entry.hwi.hw)
		inflection_match := baseword == condition.word
			|| entry.ins.any(normalize(it.inf) == condition.word)
		if !is_phrase || inflection_match {
			pronunciation := entry.hwi.prs.to_dictionary_result()
			mut notation := pronunciation.notation
			mut accents := pronunciation.accents
			for vr in entry.vrs {
				pr := vr.prs.to_dictionary_result()
				if notation == '' && pr.notation != '' {
					notation = pr.notation
				}
				for accent in pr.accents {
					accents << accent
				}
			}
			dict_entries << dictionary.Entry{
				id: entry.meta.id
				headword: baseword
				function_label: entry.fl
				grammatical_note: entry.gram
				pronunciation: dictionary.Pronunciation{
					notation: notation
					accents: accents
				}
				inflections: entry.ins.to_dictionary_result()
				definitions: entry.def.to_dictionary_result(web_url)
				variants: entry.vrs.map(dictionary.Variant{
					label: it.vl
					variant: normalize(it.va)
				})
			}
			for uro in entry.uros {
				dict_entries << dictionary.Entry{
					id: '$entry.meta.id-$uro.ure'
					headword: normalize(uro.ure)
					function_label: uro.fl
					grammatical_note: uro.gram
					pronunciation: uro.prs.to_dictionary_result()
					inflections: uro.ins.to_dictionary_result()
					definitions: uro.utxt.to_dictionary_result(web_url)
				}
			}
		}
		for dro in entry.dros {
			if (condition.to_lookup == dictionary.ToLookup.phrase && dro.drp.contains(baseword))
				|| (condition.to_lookup == dictionary.ToLookup.word
				&& match_phrase(condition.word, dro.drp)) {
				dict_entries << dictionary.Entry{
					id: '$entry.meta.id-$dro.drp'
					headword: dro.drp
					function_label: dro.gram
					definitions: dro.def.to_dictionary_result(web_url)
				}
			}
		}
	}

	return dict_entries
}

struct Meta {
pub mut:
	id           string
	uuid         string
	src          string
	section      string
	target       Target
	highlight    string
	stems        []string
	app_shortdef AppShortdef [json: 'app-shortdef']
	offensive    bool
}

fn (mut m Meta) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'id' {
				m.id = v.str()
			}
			'uuid' {
				m.uuid = v.str()
			}
			'src' {
				m.src = v.str()
			}
			'section' {
				m.section = v.str()
			}
			'target' {
				m.target.from_json(v)
			}
			'highlight' {
				m.highlight = v.str()
			}
			'stems' {
				m.stems = v.arr().map(it.str())
			}
			'app-shortdef' {
				if v.arr().len > 0 {
					m.app_shortdef.from_json(v)
				}
			}
			'offensive' {
				m.offensive = v.bool()
			}
			else {
				eprintln('unknown key in Meta: $k')
			}
		}
	}
}

struct Target {
pub mut:
	tuuid string
	tsrc  string
}

fn (mut t Target) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'tuuid' {
				t.tuuid = v.str()
			}
			'tsrc' {
				t.tsrc = v.str()
			}
			else {
				eprintln('unknown key in Target: $k')
			}
		}
	}
}

pub struct AppShortdef {
pub mut:
	hw  string
	fl  string
	def []string
}

fn (mut a AppShortdef) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'hw' {
				a.hw = v.str()
			}
			'fl' {
				a.fl = v.str()
			}
			'def' {
				a.def = v.arr().map(it.str().trim_space())
			}
			else {
				eprintln('unknown key in AppShortdef: $k')
			}
		}
	}
}

struct Hwi {
pub mut:
	hw  string
	prs []Pr
}

fn (mut h Hwi) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'hw' {
				h.hw = v.str()
			}
			'prs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					h.prs << p
				}
			}
			'altprs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					h.prs << p
				}
			}
			else {
				eprintln('unknown key in Hwi: $k')
			}
		}
	}
}

struct Pr {
pub mut:
	ipa   string
	mw    string
	l     string
	sound Sound
	pun   string
}

fn (mut p Pr) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'ipa' {
				p.ipa = v.str()
			}
			'l' {
				p.l = v.str()
			}
			'mw' {
				p.mw = v.str()
			}
			'sound' {
				p.sound.from_json(v)
			}
			'pun' {
				p.pun = v.str()
			}
			else {
				eprintln('unknown key in Pr: $k')
			}
		}
	}
}

fn (prs []Pr) to_dictionary_result() dictionary.Pronunciation {
	if prs.len == 0 {
		return dictionary.Pronunciation{}
	}
	notation := if prs[0].ipa != '' {
		'IPA'
	} else if prs[0].mw != '' {
		'MW'
	} else {
		eprintln('unknown pronunciation: ${prs[0]}')
		''
	}
	return dictionary.Pronunciation{
		notation: notation
		accents: prs.map(fn (pr Pr) dictionary.Accent {
			spelling := if pr.ipa != '' {
				pr.ipa
			} else if pr.mw != '' {
				pr.mw
			} else {
				''
			}
			return dictionary.Accent{
				label: pr.l
				spelling: spelling
			}
		})
	}
}

struct Sound {
pub mut:
	audio string
}

fn (mut s Sound) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'audio' {
				s.audio = v.str()
			}
			else {
				eprintln('unknown key in Sound: $k')
			}
		}
	}
}

struct Inf {
pub mut:
	il  string
	inf string [json: 'if']
	ifc string
	prs []Pr
}

fn (mut i Inf) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'il' {
				i.il = normalize(v.str())
			}
			'if' {
				i.inf = v.str()
			}
			'ifc' {
				i.ifc = v.str()
			}
			'prs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					i.prs << p
				}
			}
			'altprs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					i.prs << p
				}
			}
			else {
				eprintln('unknown key in Inf: $k')
			}
		}
	}
}

fn (ins []Inf) to_dictionary_result() []dictionary.Inflection {
	return ins.map(fn (inf Inf) dictionary.Inflection {
		return dictionary.Inflection{
			form_label: inf.il
			inflected_form: normalize(inf.inf)
			pronunciation: inf.prs.to_dictionary_result()
		}
	})
}

struct Uro {
pub mut:
	ure  string
	prs  []Pr
	fl   string
	ins  []Inf
	gram string
	utxt Utxt
	lbs  []string
}

fn (mut u Uro) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'ure' {
				u.ure = v.str()
			}
			'prs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					u.prs << p
				}
			}
			'altprs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					u.prs << p
				}
			}
			'fl' {
				u.fl = v.str()
			}
			'ins' {
				u.ins = v.arr().map(fn (item json2.Any) Inf {
					mut i := Inf{}
					i.from_json(item)
					return i
				})
			}
			'gram' {
				u.gram = v.str()
			}
			'utxt' {
				u.utxt.from_json(v)
			}
			'lbs' {
				u.lbs = v.arr().map(it.str())
			}
			else {
				eprintln('unknown key in Uro: $k')
			}
		}
	}
}

struct Dro {
pub mut:
	drp  string
	def  []DefinitionSection
	gram string
	vrs  []Vr
	lbs  []string
}

fn (mut d Dro) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'drp' {
				d.drp = v.str()
			}
			'def' {
				d.def = v.arr().map(fn (item json2.Any) DefinitionSection {
					mut d := DefinitionSection{}
					d.from_json(item)
					return d
				})
			}
			'gram' {
				d.gram = v.str()
			}
			'vrs' {
				d.vrs = v.arr().map(fn (item json2.Any) Vr {
					mut v := Vr{}
					v.from_json(item)
					return v
				})
			}
			'lbs' {
				d.lbs = v.arr().map(it.str())
			}
			else {
				eprintln('unknown key in Dro: $k')
			}
		}
	}
}

struct Vr {
pub mut:
	vl  string
	va  string
	prs []Pr
}

fn (mut vr Vr) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'vl' {
				vr.vl = v.str()
			}
			'va' {
				vr.va = v.str()
			}
			'prs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					vr.prs << p
				}
			}
			'altprs' {
				for pr in v.arr() {
					mut p := Pr{}
					p.from_json(pr)
					vr.prs << p
				}
			}
			else {
				eprintln('unknown key in Vr: $k')
			}
		}
	}
}

struct DefinitionSection {
pub mut:
	sls  []string
	sseq []Sense
}

fn (sections []DefinitionSection) to_dictionary_result(web_url fn (string) string) []dictionary.Definition {
	mut definitions := []dictionary.Definition{}
	for section in sections {
		for sense in section.sseq {
			mut meaning := sense.dt.text
			mut examples := sense.dt.vis.map(to_html(it, web_url))

			if sense.lbs.len > 0 {
				label := sense.lbs.map(fn (l string) string {
					return '<i>$l</i>'
				}).join(', ')
				meaning = '$label $meaning'
			}
			if sense.dt.uns.len > 0 {
				for usage_note in sense.dt.uns {
					meaning += ' &mdash; $usage_note.text'
					for example in usage_note.vis {
						examples << to_html(example, web_url)
					}
				}
			}
			if sense.sdsense.sd != '' {
				meaning += '; <i>$sense.sdsense.sd</i> $sense.sdsense.dt.text'
				for example in sense.sdsense.dt.vis {
					examples << to_html(example, web_url)
				}
				if sense.sdsense.dt.uns.len > 0 {
					for usage_note in sense.sdsense.dt.uns {
						meaning += ' &mdash; $usage_note.text'
						for example in usage_note.vis {
							examples << to_html(example, web_url)
						}
					}
				}
			}
			definitions << dictionary.Definition{
				grammatical_note: sense.sgram
				sense: to_html(meaning, web_url)
				examples: examples
			}
		}
	}
	return definitions
}

fn (mut d DefinitionSection) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'sls' {
				d.sls = v.arr().map(it.str())
			}
			'sseq' {
				empty := Sense{}
				for seq in v.arr() {
					mut sen := Sen{}
					mut bs := empty
					for item in seq.arr() {
						arr := item.arr()
						if arr.len != 2 {
							eprintln('sseq contains array.len = $arr.len array')
						}
						label, obj := arr[0].str(), arr[1]
						if label == 'bs' {
							mut sense := Sense{}
							sense.from_json(obj.as_map()['sense'] or { '' })
							bs = sense
						} else if label == 'sense' {
							mut sense := Sense{}
							sense.from_json(obj)
							if sen.sgram != '' && sense.sgram == '' {
								sense.sgram = sen.sgram
							}
							if bs != empty {
								sense.dt.text = '$bs.dt.text $sense.dt.text'
							}
							d.sseq << sense
						} else if label == 'sen' {
							sen.from_json(obj)
						} else if label == 'pseq' {
							mut bs2 := empty
							for pseq in obj.arr() {
								arr2 := pseq.arr()
								label2, obj2 := arr2[0].str(), arr2[1]

								if label2 == 'bs' {
									mut sense := Sense{}
									sense.from_json(obj2.as_map()['sense'] or { '' })
									bs2 = sense
								} else if label2 == 'sense' {
									mut sense := Sense{}
									sense.from_json(obj2)
									if bs2 != empty {
										sense.dt.text = '$bs2.dt.text $sense.dt.text'
									}

									d.sseq << sense
								} else {
									eprintln('label = $label is not allowed in pseq')
								}
							}
						} else {
							eprintln('label = $label is not allowed in sseq')
						}
					}
				}
			}
			else {
				eprintln('unknown key in DefinitionSection: $k')
			}
		}
	}
}

struct Sen {
pub mut:
	sn    string
	sgram string
}

fn (mut s Sen) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'sn' {
				s.sn = v.str()
			}
			'sgram' {
				s.sgram = v.str()
			}
			else {
				eprintln('unknown key in Sen: $k')
			}
		}
	}
}

struct Sense {
pub mut:
	sn      string
	dt      DefinitionText
	sgram   string
	sdsense Sdsense
	lbs     []string
	sls     []string
}

fn (mut s Sense) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'sn' {
				s.sn = v.str()
			}
			'dt' {
				s.dt.from_json(v)
			}
			'sgram' {
				s.sgram = v.str()
			}
			'sdsense' {
				s.sdsense.from_json(v)
			}
			'lbs' {
				s.lbs = v.arr().map(it.str())
			}
			'sls' {
				s.sls = v.arr().map(it.str())
			}
			'sphrasev' {
				// Do nothing
			}
			'snotebox' {
				// Do nothing
			}
			else {
				eprintln('unknown key in Sense: $k')
			}
		}
	}
}

struct Sdsense {
pub mut:
	sd string
	dt DefinitionText
}

fn (mut sd Sdsense) from_json(f json2.Any) {
	mp := f.as_map()

	for k, v in mp {
		match k {
			'sd' {
				sd.sd = v.str()
			}
			'dt' {
				sd.dt.from_json(v)
			}
			else {
				eprintln('unknown key in Sdsense: $k')
			}
		}
	}
}

struct DefinitionText {
pub mut:
	text  string
	vis   []string
	uns   []UsageNote
	snote Snote
}

fn (mut d DefinitionText) from_json(f json2.Any) {
	mut texts := []string{}
	mut vis := []string{}
	mut uns := []UsageNote{}

	mut wsgram := ''
	for tuple in f.arr() {
		items := tuple.arr()
		label, obj := items[0].str(), items[1]
		if label == 'text' {
			texts << obj.str().trim_space()
		} else if label == 'vis' {
			for example in obj.arr() {
				mp := example.as_map()
				if wsgram == '' {
					vis << (mp['t'] or { '' }).str().trim_space()
				} else {
					vis << '[$wsgram] ' + (mp['t'] or { '' }).str().trim_space()
				}
			}
		} else if label == 'uns' {
			mut note := UsageNote{}
			note.from_json(obj)
			uns << note
		} else if label == 'snote' {
			mut snote := Snote{}
			snote.from_json(obj)
			d.snote = snote
		} else if label == 'wsgram' {
			wsgram = obj.str()
		} else if label in ['ca', 'srefs', 'urefs'] {
			// nothing to do
		} else {
			eprintln('unknown label $label in DefinitionText')
		}
	}

	d.text = texts.join('. ')
	d.vis = vis
	d.uns = uns
}

type UsageNote = DefinitionText

fn (mut u UsageNote) from_json(f json2.Any) {
	mut texts := []string{}
	mut vis := []string{}

	for usage_notes in f.arr() {
		for tuple in usage_notes.arr() {
			items := tuple.arr()
			label, obj := items[0].str(), items[1]
			if label == 'text' {
				texts << obj.str().trim_space()
			} else if label == 'vis' {
				for example in obj.arr() {
					mp := example.as_map()
					vis << (mp['t'] or { '' }).str().trim_space()
				}
			} else {
				eprintln('unknown label $label in UsageNote')
			}
		}
	}

	u.text = texts.join(' {mdash} ')
	u.vis = vis
}

struct Utxt {
pub mut:
	text string
	vis  []string
	uns  []UsageNote
}

fn (u Utxt) to_dictionary_result(web_url fn (string) string) []dictionary.Definition {
	if u.vis.len == 0 {
		return []
	}
	mut meaning := u.text
	mut examples := u.vis.map(to_html(it, web_url))
	if u.uns.len > 0 {
		for usage_note in u.uns {
			meaning += ' &mdash; $usage_note.text'
			for example in usage_note.vis {
				examples << to_html(example, web_url)
			}
		}
	}

	return [dictionary.Definition{
		sense: to_html(meaning, web_url)
		examples: examples
	}]
}

fn (mut u Utxt) from_json(f json2.Any) {
	mut texts := []string{}
	mut vis := []string{}
	mut uns := []UsageNote{}

	mut wsgram := ''
	for tuple in f.arr() {
		items := tuple.arr()
		label, obj := items[0].str(), items[1]
		if label == 'text' {
			texts << obj.str().trim_space()
		} else if label == 'vis' {
			for example in obj.arr() {
				mp := example.as_map()
				if wsgram == '' {
					vis << (mp['t'] or { '' }).str().trim_space()
				} else {
					vis << '[$wsgram] ' + (mp['t'] or { '' }).str().trim_space()
				}
			}
		} else if label == 'uns' {
			mut note := UsageNote{}
			note.from_json(obj)
			uns << note
		} else if label == 'wsgram' {
			wsgram = obj.str()
		} else if label == 'snotebox' {
			// nothing to do
		} else {
			eprintln('unknown label $label in Utxt.')
		}
	}

	u.text = texts.join(' {mdash} ')
	u.vis = vis
	u.uns = uns
}

struct Snote {
pub mut:
	t   string
	vis []string
}

fn (mut s Snote) from_json(f json2.Any) {
	mut texts := []string{}
	mut vis := []string{}

	for tuple in f.arr() {
		items := tuple.arr()
		label, obj := items[0].str(), items[1]
		if label == 't' {
			texts << obj.str()
		} else if label == 'vis' {
			for example in obj.arr() {
				mp := example.as_map()
				vis << (mp['t'] or { '' }).str().trim_space()
			}
		} else {
			eprintln('unknown label $label in Snote')
		}
	}
	s.t = texts.join('. ')
	s.vis = vis
}

fn candidate(word string, entry Entry) bool {
	return word.to_lower() in entry.meta.stems
}

fn match_phrase(search string, drp string) bool {
	if search == drp {
		return true
	}

	search_segments := search.split(' ').map(it.trim_space())
	drp_segements := drp.split(' ').map(it.trim_space())

	if search_segments.len != drp_segements.len {
		return false
	}

	next: for i, seg in search_segments {
		seg2 := drp_segements[i]
		for word in seg2.split('/').map(it.trim_space()) {
			if seg == word {
				continue next
			}
		}
		return false
	}

	return true
}

const tag_map = {
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
	'mdash':   '&mdash; '
	'dx_def':  '('
	'/dx_def': ')'
	' or ':    'or'
}

fn to_html(sentence string, web_url fn (string) string) string {
	mut before, mut after := sentence.before('{'), sentence.all_after('{')
	mut res := ''

	for before != after {
		res += before // TODO: HTML escape

		tag := after.before('}')
		after = after.all_after('}')
		if tag in mw.tag_map {
			res += mw.tag_map[tag]
		} else if tag.contains('|') {
			segments := tag.split('|')
			link_word := segments[1].split(':')[0]
			res += '<a target="_blank" href="${web_url(link_word)}">$link_word</a>'
		} else {
			eprintln('unknown tag: $tag in sentence: $sentence')
		}
		before, after = after.before('{'), after.all_after('{')
	}
	res += before // TODO: HTML escape

	return res
}

fn normalize(headword string) string {
	return headword.replace('*', '')
}
