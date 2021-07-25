module server

import anki
import dictionary
import takkyuuplayer.bytebuf
import takkyuuplayer.streader
import vweb

struct App {
	vweb.Context
	dictionaries []dictionary.Dictionary
}

pub fn new_app(dictionaries []dictionary.Dictionary) &App {
	mut app := &App{
		dictionaries: dictionaries
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

	app.add_header('X-Content-Type-Options', 'nosniff')
	app.add_header('Content-Type', 'text/tab-separated-values; charset=UTF-8')
	app.add_header('Content-Disposition', 'attachment; filename=anki.tsv')

	runner := anki.new(app.dictionaries, anki.to_card[card_type])
	mut input := streader.new(words)
	mut output := bytebuf.Buffer{}
	runner.run(input, output)

	return app.text(output.str())
}
