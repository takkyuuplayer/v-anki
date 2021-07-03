module dictionary

pub struct Result {
pub:
	word       string
	dictionary string
	web_url    string
	entries    []Entry
	suggestion []string
}

pub struct Entry {
pub:
	id               string
	headword         string
	function_label   string
	grammatical_note string
	pronunciation    Pronunciation
	inflections      []Inflection
	definitions      []Definition
}

pub struct Definition {
pub:
	grammatical_note string
	sense            string
	examples         []string
}

pub struct Inflection {
pub:
	form_label     string
	inflected_form string
	pronunciation  Pronunciation
}

pub struct Pronunciation {
pub:
	notation string
	accents  []Accent
}

pub struct Accent {
pub:
	label    string
	spelling string
	audio    string
}
