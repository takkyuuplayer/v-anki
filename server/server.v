module server

import anki
import dictionary
import net.http
import strconv
import takkyuuplayer.bytebuf
import takkyuuplayer.streader
import vweb

struct App {
	vweb.Context
mut:
	chunking     bool
	wrote_header bool
	dictionaries shared []dictionary.Dictionary
}

pub fn (mut app App) write(buf []byte) ?int {
	if app.Context.done {
		return 0
	}

	if !app.wrote_header {
		app.write_header() or {
			eprintln(err)
			return err
		}
	}

	if app.chunking {
		app.conn.write(strconv.v_sprintf('%x\r\n', buf.len).bytes()) ?
		n := app.conn.write(buf) ?
		app.conn.write('\r\n'.bytes()) ?
		return n
	} else {
		return app.conn.write(buf)
	}
}

fn (mut app App) close() {
	if app.Context.done {
		return
	}
	app.Context.done = true

	if !app.chunking {
		return
	}

	app.conn.write('0\r\n\r\n'.bytes()) or {}
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
	defer {
		app.close()
	}
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
	mut output := app
	mut err_output := bytebuf.Buffer{}
	runner.run(input, output, err_output)
	app.write(err_output.str().bytes()) or { eprintln(err) }

	return vweb.not_found()
}
