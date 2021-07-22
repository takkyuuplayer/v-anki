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

	to_card := anki.to_card['basic']
	runner := anki.new(dictionaries, to_card)
	runner.run(os.stdin(), os.stdout())
}
