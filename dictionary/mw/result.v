// https://dictionaryapi.com/products/json
module mw

import x.json2

type Suggestion = []string
type Entries = []Entry
type Result = Suggestion | Entries

pub fn parse_response(body string) ?Result {
	raw_entries := json2.raw_decode(body) ?

	mut entries := []Entry{}
	for _, entry in raw_entries.arr() {
		mut e := Entry{}
		e.from_json(entry)
		entries << e
	}

	return Result(Entries(entries))
}

struct Entry {
pub mut:
	meta      Meta
	hwi       Hwi
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
	a.def = mp['def'].arr().map(it.str())
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
	for pr in mp['prs'].arr() {
		mut p := Pr{}
		p.from_json(pr)
		prs << p
	}
	h.prs = prs
}

struct Pr {
pub mut:
	ipa   string
	l     string
	sound Sound
}

fn (mut p Pr) from_json(f json2.Any) {
	mp := f.as_map()

	p.ipa = mp['ipa'].str()
	p.l = mp['l'].str()
	mut sound := Sound{}
	sound.from_json(mp['sound'])
	p.sound = sound
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

	i.il = mp['il'].str()
	i.inf = mp['if'].str()
	i.ifc = mp['ifc'].str()
	if 'prs' in mp {
		mut prs := []Pr{}
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
	}
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
	if 'prs' in mp {
		mut prs := []Pr{}
		for pr in mp['prs'].arr() {
			mut p := Pr{}
			p.from_json(pr)
			prs << p
		}
		u.prs = prs
	}
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
	vl string
	va string
}

fn (mut v Vr) from_json(f json2.Any) {
	mp := f.as_map()
	v.vl = mp['vl'].str()
	v.va = mp['va'].str()
}

struct DefinitionSection {
pub mut:
	sls  []string
	sseq []Sense
}

fn (mut d DefinitionSection) from_json(f json2.Any) {
	mp := f.as_map()

	if 'sls' in mp {
		d.sls = mp['sls'].arr().map(it.str())
	}
	mut sseq := []Sense{}
	for seq in mp['sseq'].arr() {
		for sen in seq.arr() {
			arr := sen.arr()
			if arr.len != 2 {
				eprintln('sseq contains array.len = $arr.len array')
			}
			label, obj := arr[0].str(), arr[1]
			if label == 'sense' {
				mut sense := Sense{}
				sense.from_json(obj)
				sseq << sense
			} else {
				eprintln('label = $label is not allowed in sseq')
			}
		}
	}
	d.sseq = sseq
}

struct Sense {
pub mut:
	sn string
	dt DefinitionText
	//	et
	//	ins
	//	lbs
	//	prs
	//	sdsense
	//	sgram
	//	sls
	//	vrs
}

fn (mut s Sense) from_json(f json2.Any) {
	mp := f.as_map()

	s.sn = mp['sn'].str()
	mut dt := DefinitionText{}
	dt.from_json(mp['dt'])
	s.dt = dt
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

	for tuple in f.arr() {
		items := tuple.arr()
		label, obj := items[0].str(), items[1]
		if label == 'text' {
			texts << obj.str()
		} else if label == 'vis' {
			for example in obj.arr() {
				mp := example.as_map()
				vis << mp['t'].str()
			}
		} else if label == 'uns' {
			mut note := UsageNote{}
			if obj.arr().len != 1 {
				eprintln('UsageNote length with $obj.arr().len')
			}
			note.from_json(obj.arr()[0])
			uns << note
		} else if label == 'snote' {
			mut snote := Snote{}
			snote.from_json(obj)
		}
	}

	d.text = texts.join('; ')
	d.vis = vis
	d.uns = uns
}

type UsageNote = DefinitionText

// type Utxt = DefinitionText

struct Utxt {
pub mut:
	vis []string
	uns []UsageNote
}

fn (mut u Utxt) from_json(f json2.Any) {
	mut vis := []string{}
	mut uns := []UsageNote{}

	for tuple in f.arr() {
		items := tuple.arr()
		label, obj := items[0].str(), items[1]
		if label == 'vis' {
			for example in obj.arr() {
				mp := example.as_map()
				vis << mp['t'].str()
			}
		} else if label == 'uns' {
			mut note := UsageNote{}
			if obj.arr().len != 1 {
				eprintln('UsageNote length with $obj.arr().len')
			}
			note.from_json(obj.arr()[0])
			uns << note
		} else {
			eprintln('unknown label $label in Utxt')
		}
	}

	u.vis = vis
	u.uns = uns
}

struct Snote {
pub mut:
	t   string
	vis []string
	// ri
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
				vis << mp['t'].str()
			}
		}
	}
	s.t = texts.join('; ')
	s.vis = vis
}
