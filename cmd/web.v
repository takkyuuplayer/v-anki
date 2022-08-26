module cmd

import vweb
import server
import cli
import dictionary
import dictionary.mw
import envars

pub fn new_web_cmd() cli.Command {
	mut c := cli.Command{
		name: 'web'
		description: 'Boot Anki Card Generator Server'
		execute: web
	}

	return c
}

fn web(c cli.Command) ? {
	env := envars.load()?

	mut dictionaries := []dictionary.Dictionary{}
	dictionaries << mw.new_learners(env.mw_learners_key)
	dictionaries << mw.new_collegiate(env.mw_collegiate_key)

	vweb.run(server.new_app(dictionaries), env.port)
}
