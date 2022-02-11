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
		description: 'Prints tsv for Anki from STDIN'
		usage: '<words.txt'
		execute: cli
	}
	c.add_flag(cli.Flag{
		flag: .string
		name: 'card'
		default_value: ['basic']
		description: 'the type of card to generate. basic|sentences'
	})
	c.add_flag(cli.Flag{
		flag: .string
		name: 'to_lookup'
		default_value: ['word']
		description: 'word|phrase'
	})

	return c
}

fn cli(c cli.Command) ? {
	card_type := c.flags.get_string('card') ?
	to_lookup := c.flags.get_string('to_lookup') ?

	if to_lookup !in anki.to_lookup {
		return error('Only -to_lookup=word|phrase is supported')
	}

	env := envars.load() ?

	mut dictionaries := []dictionary.Dictionary{}
	dictionaries << mw.new_learners(env.mw_learners_key)
	dictionaries << mw.new_collegiate(env.mw_collegiate_key)

	to_card := anki.to_card(anki.to_lookup[to_lookup], card_type) ?
	runner := anki.new(dictionaries, anki.to_lookup[to_lookup], to_card)
	mut input := os.stdin()
	mut output := os.stdout()
	mut err_output := os.stderr()
	runner.run(input, output, err_output)
	output.flush()
	err_output.flush()
}
