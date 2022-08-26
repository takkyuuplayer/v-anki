module server

import anki
import dictionary
import net.http
import takkyuuplayer.bytebuf
import takkyuuplayer.chunkio
import takkyuuplayer.streader
import vweb

struct App {
	vweb.Context
mut:
	wrote_header bool
	dictionaries shared []dictionary.Dictionary
}

fn (mut app App) write_header() ? {
	if app.Context.done {
		return
	}
	if app.wrote_header {
		return
	}
	app.wrote_header = true

	mut resp := http.Response{
		header: app.Context.header
	}
	resp.set_version(.v1_1)
	resp.set_status(http.status_from_int(200))

	app.Context.conn.write(resp.bytes())?
}

pub fn new_app(dictionaries []dictionary.Dictionary) &App {
	mut app := &App{}
	lock app.dictionaries {
		app.dictionaries = dictionaries
	}
	app.serve_static('/', 'static/index.html')

	return app
}

['/cards'; post]
pub fn (mut app App) lookup() vweb.Result {
	words := app.form['words']
	card_type := app.form['cardType']
	to_lookup := app.form['toLookup']

	if to_lookup !in anki.to_lookup {
		return app.redirect('/')
	}

	to_card := anki.to_card(anki.to_lookup[to_lookup], card_type) or { return app.redirect('/') }
	runner := rlock app.dictionaries {
		anki.new(app.dictionaries, anki.to_lookup[to_lookup], to_card)
	}

	mut input := streader.new(words)
	mut output := chunkio.new_writer(writer: app.Context.conn, size: 1024)
	mut err_output := bytebuf.Buffer{}

	app.set_content_type('text/tab-separated-values; charset=UTF-8')
	app.add_header('X-Content-Type-Options', 'nosniff')
	app.add_header('Content-Disposition', 'attachment; filename=anki.tsv')
	app.add_header('Transfer-Encoding', 'chunked')
	app.add_header('Connection', 'keep-alive')
	app.write_header() or { eprintln(err) }

	runner.run(input, mut output, mut err_output)
	if err_output.str().len > 0 {
		output.write(err_output.str().bytes()) or { eprintln(err) }
	}
	output.close() or { eprintln(err) }

	// To return vweb.Result{}
	return vweb.not_found()
}
