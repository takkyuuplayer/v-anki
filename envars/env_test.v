import envars
import os

fn test_load() {
	os.unsetenv('MW_LEARNERS_KEY')
	os.unsetenv('MW_COLLEGIATE_KEY')
	mut env := envars.load() or { envars.Envars{} }

	assert env.mw_learners_key == ''
	assert env.mw_collegiate_key == ''

	os.setenv('MW_LEARNERS_KEY', 'key1', true)
	os.setenv('MW_COLLEGIATE_KEY', 'key2', true)

	env = envars.load() or { panic(err) }

	assert env.mw_learners_key == 'key1'
	assert env.mw_collegiate_key == 'key2'
	assert env.port == 8080

	os.setenv('PORT', '10080', true)
	env = envars.load() or { panic(err) }
	assert env.port == 10080
}
