module cmd

import anki
import cli
import dictionary
import dictionary.mw
import envars
import os

pub fn new_cli_cmd() cli.Command {
	mut c := cli.Command{
		name: 'cli'
		description: 'Prints csv for Anki from STDIN'
		usage: '<words.txt'
		execute: cli
	}
	c.add_flag(cli.Flag{
		flag: .string
		name: 'card'
		default_value: ['basic']
		description: 'the type of card to generate. basic|sentences'
	})

	return c
}

fn cli(c cli.Command) ? {
	card_type := c.flags.get_string('card') ?

	if card_type !in anki.to_card {
		return error('Only -card=basic|sentences is supported')
	}

	env := envars.load() ?

	mut dictionaries := []dictionary.Dictionary{}
	dictionaries << mw.new_learners(env.mw_learners_key)
	dictionaries << mw.new_collegiate(env.mw_collegiate_key)

	to_card := anki.to_card[card_type]
	runner := anki.new(dictionaries, to_card)
	mut input := os.stdin()
	mut output := os.stdout()
	mut err_output := os.stderr()
	runner.run(input, output, err_output)
	output.flush()
	err_output.flush()
}
