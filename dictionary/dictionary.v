module dictionary

pub enum ToLookup {
	// words, phrases and derivative words matching the search.
	word
	// phrases including the search.
	phrase
}

pub struct LookupCondition {
pub:
	word      string
	to_lookup ToLookup = ToLookup.word
}

interface Dictionary {
	lookup(LookupCondition) ?Result
}
