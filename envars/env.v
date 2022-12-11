module envars

import os

pub struct Envars {
pub:
	mw_learners_key   string
	mw_collegiate_key string
	port              u16
}

pub fn load() !Envars {
	return Envars{
		mw_learners_key: must_get('MW_LEARNERS_KEY')!
		mw_collegiate_key: must_get('MW_COLLEGIATE_KEY')!
		port: u16(get('PORT', '8080').int())
	}
}

fn get(key string, default string) string {
	env := os.getenv(key)
	if env == '' {
		return default
	}
	return env
}

fn must_get(key string) !string {
	env := os.getenv(key)
	if env == '' {
		return error('ENV{$key} does not exist')
	}
	return env
}
