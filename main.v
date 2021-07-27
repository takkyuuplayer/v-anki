module main

import cli
import os
import cmd

fn main() {
	mut c := cli.Command{
		name: 'anki'
		description: 'anki card generator'
		version: '0.0.1'
	}
	c.add_command(cmd.new_cli_cmd())
	c.add_command(cmd.new_web_cmd())
	c.setup()
	c.parse(os.args)
}
