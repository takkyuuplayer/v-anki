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
	meta      Meta
	hwi       Hwi
	vrs       []Vr
	hom       int
	fl        string
	lbs       []string
	ins       []Inf
	gram      string
	def       []DefinitionSection
	uros      []Uro
	dros      []Dro
	dxnls     []string
	short_def []string
}

fn (mut e Entry) from_json(f json2.Any) {
	mp := f.as_map()

	mut meta := Meta{}
	meta.from_json(mp['meta'])
	e.meta = meta
	mut hwi := Hwi{}
	hwi.from_json(mp['hwi'])
	e.hwi = hwi
	e.hom = mp['hom'].int()
	e.fl = mp['fl'].str()
	if 'lbs' in mp {
		e.lbs = mp['lbs'].arr().map(it.str())
	}
	if 'ins' in mp {
		mut ins := []Inf{}
		for inflection in mp['ins'].arr() {
			mut i := Inf{}
			i.from_json(inflection)
			ins << i
		}
		e.ins = ins
	}
	e.gram = mp['gram'].str()
	mut def := []DefinitionSection{}
	if 'def' in mp {
		for ds in mp['def'].arr() {
			mut d := DefinitionSection{}
			d.from_json(ds)
			def << d
		}
	}
	e.def = def
	if 'uros' in mp {
		mut uros := []Uro{}
		for item in mp['uros'].arr() {
			mut uro := Uro{}
			uro.from_json(item)
			uros << uro
		}
		e.uros = uros
	}
	if 'dros' in mp {
		mut dros := []Dro{}
		for item in mp['dros'].arr() {
			mut dro := Dro{}
			dro.from_json(item)
			dros << dro
		}
		e.dros = dros
	}
	if 'vrs' in mp {
		mut vrs := []Vr{}
		for item in mp['vrs'].arr() {
			mut vr := Vr{}
			vr.from_json(item)
			vrs << vr
		}
		e.vrs = vrs
	}
}

pub fn (entries []Entry) to_dictionary_result(word string, web_url fn (string) string) []dictionary.Entry {
	mut dict_entries := []dictionary.Entry{}
	is_phrase := word.split(' ').len > 1
	for entry in entries {
		if !candidate(word, entry) {
			continue
		}
		inflection_match := normalize(entry.hwi.hw) == word
			|| entry.ins.any(normalize(it.inf) == word)
		if !is_phrase {
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
				headword: normalize(entry.hwi.hw)
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
		} else if inflection_match {
			dict_entries << dictionary.Entry{
				id: entry.meta.id
				headword: normalize(entry.hwi.hw)
				function_label: entry.fl
				grammatical_note: entry.gram
				pronunciation: entry.hwi.prs.to_dictionary_result()
				inflections: entry.ins.to_dictionary_result()
				definitions: entry.def.to_dictionary_result(web_url)
			}
		}
		for dro in entry.dros {
			if !match_phrasal_verb(word, dro.drp) {
				continue
			}
			dict_entries << dictionary.Entry{
				id: '$entry.meta.id-$dro.drp'
				headword: dro.drp
				function_label: dro.gram
				definitions: dro.def.to_dictionary_result(web_url)
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

	m.id = mp['id'].str()
	m.uuid = mp['uuid'].str()
	m.src = mp['src'].str()
	m.section = mp['section'].str()
	if 'target' in mp {
		mut target := Target{}
		target.from_json(mp['target'])
		m.target = target
	}
	if 'highlight' in mp {
		m.highlight = mp['highlight'].str()
	}
	m.stems = mp['stems'].arr().map(it.str())
	if mp['app-shortdef'].arr().len == 0 {
		// invalid data in junk.json
	} else {
		mut app_shortdef := AppShortdef{}
		app_shortdef.from_json(mp['app-shortdef'])
		m.app_shortdef = app_shortdef
		m.offensive = mp['offensive'].bool()
	}
}

struct Target {
pub mut:
	tuuid string
	tsrc  string
}

fn (mut t Target) from_json(f json2.Any) {
	mp := f.as_map()

	t.tuuid = mp['tuuid'].str()
	t.tsrc = mp['tsrc'].str()
}

pub struct AppShortdef {
pub mut:
	hw  string
	fl  string
	def []string
}

fn (mut a AppShortdef) from_json(f json2.Any) {
	mp := f.as_map()

	a.hw = mp['hw'].str()
	a.fl = mp['fl'].str()
	a.def = mp['def'].arr().map(it.str().trim_space())
}

struct Hwi {
pub mut:
	hw  string
	prs []Pr
}

fn (mut h Hwi) from_json(f json2.Any) {
	mp := f.as_map()

	h.hw = mp['hw'].str()
	mut prs := []Pr{}
	if 'prs' in mp {
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	if 'altprs' in mp {
		for pr in mp['altprs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	h.prs = prs
}

struct Pr {
pub mut:
	ipa   string
	mw    string
	l     string
	sound Sound
}

fn (mut p Pr) from_json(f json2.Any) {
	mp := f.as_map()

	p.ipa = mp['ipa'].str()
	p.l = mp['l'].str()
	p.mw = mp['mw'].str()
	mut sound := Sound{}
	sound.from_json(mp['sound'])
	p.sound = sound
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

	s.audio = mp['audio'].str()
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

	i.il = normalize(mp['il'].str())
	i.inf = mp['if'].str()
	i.ifc = mp['ifc'].str()
	mut prs := []Pr{}
	if 'prs' in mp {
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	if 'altprs' in mp {
		for pr in mp['altprs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	i.prs = prs
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
}

fn (mut u Uro) from_json(f json2.Any) {
	mp := f.as_map()

	u.ure = mp['ure'].str()
	mut prs := []Pr{}
	if 'prs' in mp {
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	if 'altprs' in mp {
		for pr in mp['altprs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	u.prs = prs
	u.fl = mp['fl'].str()
	if 'ins' in mp {
		mut ins := []Inf{}
		for inflection in mp['ins'].arr() {
			mut i := Inf{}
			i.from_json(inflection)
			ins << i
		}
		u.ins = ins
	}
	u.gram = mp['gram'].str()

	if 'utxt' in mp {
		mut utxt := Utxt{}
		utxt.from_json(mp['utxt'])
		u.utxt = utxt
	}
}

struct Dro {
pub mut:
	drp  string
	def  []DefinitionSection
	gram string
	vrs  []Vr
}

fn (mut d Dro) from_json(f json2.Any) {
	mp := f.as_map()

	d.drp = mp['drp'].str()
	mut def := []DefinitionSection{}
	for item in mp['def'].arr() {
		mut ds := DefinitionSection{}
		ds.from_json(item)
		def << ds
	}
	d.def = def
	d.gram = mp['gram'].str()
	if 'vrs' in mp {
		mut vrs := []Vr{}
		for item in mp['vrs'].arr() {
			mut vr := Vr{}
			vr.from_json(item)
			vrs << vr
		}
		d.vrs = vrs
	}
}

struct Vr {
pub mut:
	vl  string
	va  string
	prs []Pr
}

fn (mut v Vr) from_json(f json2.Any) {
	mp := f.as_map()
	v.vl = mp['vl'].str()
	v.va = mp['va'].str()

	mut prs := []Pr{}
	if 'prs' in mp {
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	if 'altprs' in mp {
		for pr in mp['altprs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
	v.prs = prs
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
			if sense.sdsense.sd != '' {
				meaning += '; <i>$sense.sdsense.sd</i> $sense.sdsense.dt.text'
				for example in sense.sdsense.dt.vis {
					examples << to_html(example, web_url)
				}
			}
			if sense.dt.uns.len > 0 {
				for usage_note in sense.dt.uns {
					meaning += ' &mdash; $usage_note.text'
					for example in usage_note.vis {
						examples << to_html(example, web_url)
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

	if 'sls' in mp {
		d.sls = mp['sls'].arr().map(it.str())
	}
	empty := Sense{}
	mut sseq := []Sense{}
	for seq in mp['sseq'].arr() {
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
				sense.from_json(obj.as_map()['sense'])
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
				sseq << sense
			} else if label == 'sen' {
				sen.from_json(obj)
			} else if label == 'pseq' {
				mut bs2 := empty
				for pseq in obj.arr() {
					arr2 := pseq.arr()
					label2, obj2 := arr2[0].str(), arr2[1]

					if label2 == 'bs' {
						mut sense := Sense{}
						sense.from_json(obj2.as_map()['sense'])
						bs2 = sense
					} else if label2 == 'sense' {
						mut sense := Sense{}
						sense.from_json(obj2)
						if bs2 != empty {
							sense.dt.text = '$bs2.dt.text $sense.dt.text'
						}

						sseq << sense
					} else {
						eprintln('label = $label is not allowed in pseq')
					}
				}
			} else {
				eprintln('label = $label is not allowed in sseq')
			}
		}
	}
	d.sseq = sseq
}

struct Sen {
pub mut:
	sn    string
	sgram string
}

fn (mut s Sen) from_json(f json2.Any) {
	mp := f.as_map()

	s.sn = mp['sn'].str()
	if 'sgram' in mp {
		s.sgram = mp['sgram'].str()
	}
}

struct Sense {
pub mut:
	sn      string
	dt      DefinitionText
	sgram   string
	sdsense Sdsense
}

fn (mut s Sense) from_json(f json2.Any) {
	mp := f.as_map()

	s.sn = mp['sn'].str()
	if 'dt' in mp {
		mut dt := DefinitionText{}
		dt.from_json(mp['dt'])
		s.dt = dt
	}
	if 'sgram' in mp {
		s.sgram = mp['sgram'].str()
	}
	if 'sdsense' in mp {
		mut sdsense := Sdsense{}
		sdsense.from_json(mp['sdsense'])
		s.sdsense = sdsense
	}
}

struct Sdsense {
pub mut:
	sd string
	dt DefinitionText
}

fn (mut sd Sdsense) from_json(f json2.Any) {
	mp := f.as_map()

	sd.sd = mp['sd'].str()
	if 'dt' in mp {
		mut dt := DefinitionText{}
		dt.from_json(mp['dt'])
		sd.dt = dt
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
					vis << mp['t'].str().trim_space()
				} else {
					vis << '[$wsgram] ' + mp['t'].str().trim_space()
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
					vis << mp['t'].str().trim_space()
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
					vis << mp['t'].str().trim_space()
				} else {
					vis << '[$wsgram] ' + mp['t'].str().trim_space()
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
				vis << mp['t'].str().trim_space()
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

fn match_phrasal_verb(search string, drp string) bool {
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
