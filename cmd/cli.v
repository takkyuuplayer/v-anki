module main

import anki
import dictionary
import dictionary.mw
import envars
import os
import zztkm.vdotenv

fn main() {
	vdotenv.load()
	env := envars.load() ?

	mut dictionaries := []dictionary.Dictionary{}
	dictionaries << mw.new_learners(env.mw_learners_key)
	dictionaries << mw.new_collegiate(env.mw_collegiate_key)

	runner := anki.new(dictionaries, anki.to_basic_card)
	runner.run(os.stdin(), os.stdout())
}
