module main

import anki
import dictionary
import dictionary.mw
import envars
import os

fn main() {
	env := envars.load() ?

	mut dictionaries := []dictionary.Dictionary{}
	dictionaries << mw.new_learners(env.mw_learners_key)
	dictionaries << mw.new_collegiate(env.mw_collegiate_key)

	anki.run(dictionaries, os.stdin(), os.stdout())
}
