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
	chunking     bool
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

	if !app.Context.header.contains(http.CommonHeader.content_length) {
		app.add_header('Transfer-Encoding', 'chunked')
		app.chunking = true
	}
	header := http.new_header_from_map({
		http.CommonHeader.connection: 'keep-alive'
	}).join(app.Context.header)

	mut resp := http.Response{
		header: header
	}
	resp.set_version(.v1_1)
	resp.set_status(http.status_from_int(200))

	app.Context.conn.write(resp.bytes()) ?
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

	if card_type !in anki.to_card {
		return app.redirect('/')
	}

	app.set_content_type('text/tab-separated-values; charset=UTF-8')
	app.add_header('X-Content-Type-Options', 'nosniff')
	app.add_header('Content-Disposition', 'attachment; filename=anki.tsv')

	runner := rlock app.dictionaries {
		anki.new(app.dictionaries, anki.to_card[card_type])
	}

	mut input := streader.new(words)
	mut output := chunkio.new_writer(writer: app.Context.conn)
	mut err_output := bytebuf.Buffer{}

	app.write_header() or {}
	runner.run(input, output, err_output)
	if err_output.str().len > 0 {
		output.write(err_output.str().bytes()) or { eprintln(err) }
	}
	output.close() or {}

	// To return vweb.Result{}
	return vweb.not_found()
}
