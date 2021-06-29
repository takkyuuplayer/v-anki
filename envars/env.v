module envars

import os

pub struct Envars {
pub:
	mw_learners_key   string
	mw_collegiate_key string
}

pub fn load() ?Envars {
	return Envars{
		mw_learners_key: must_get('MW_LEARNERS_KEY') ?
		mw_collegiate_key: must_get('MW_COLLEGIATE_KEY') ?
	}
}

fn must_get(key string) ?string {
	env := os.getenv(key)
	if env == '' {
		return error('ENV{$key} does not exist')
	}
	return env
}
