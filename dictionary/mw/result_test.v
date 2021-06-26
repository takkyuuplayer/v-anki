module mw_test

import mw
import os

fn test_parse_response() ? {
	{
		res := mw.parse_response(load('testdata/learners/test.json')) ?

		assert res.len == 10

		first := res[0]
		assert first.meta.id == 'test:1'
		assert first.meta.uuid == '050b619c-ffad-4eaf-ba0a-93e9dab0e278'
		assert first.meta.src == 'learners'
		assert first.meta.section == 'alpha'
		assert first.meta.target.tuuid == ''
		assert first.meta.target.tsrc == ''
		assert first.meta.highlight == 'yes'
		assert first.meta.stems.len == 22
		assert first.meta.stems[0] == 'test'
		assert first.meta.offensive == false
		assert first.meta.app_shortdef.hw == 'test:1'
		assert first.meta.app_shortdef.fl == 'noun'
		assert first.meta.app_shortdef.def.len == 3
		assert first.meta.app_shortdef.def[0] == "{bc} a set of questions or problems that are designed to measure a person's knowledge, skills, or abilities"
		assert first.hwi.hw == 'test'
		assert first.hwi.prs.len == 1
		assert first.hwi.prs[0].ipa == 'ˈtɛst'
		assert first.hwi.prs[0].sound.audio == 'test0001'
		assert first.hom == 1
		assert first.fl == 'noun'
		assert first.lbs.len == 0
		assert first.ins.len == 1
		assert first.ins[0].inf == 'tests'
		assert first.ins[0].il == 'plural'
		assert first.gram == 'count'
		assert first.def.len == 1
		assert first.def[0].sls.len == 0
		assert first.def[0].sseq.len == 6
		assert first.def[0].sseq[0].sn == '1'
		assert first.def[0].sseq[0].dt.text == "{bc}a set of questions or problems that are designed to measure a person's knowledge, skills, or abilities ; {dx}see also {dxt|intelligence test||} {dxt|rorschach test||} {dxt|screen test||}{/dx}"
		assert first.def[0].sseq[0].dt.vis.len == 9
		assert first.def[0].sseq[0].dt.vis.len == 9
		assert first.def[0].sseq[3].dt.uns.len == 1
		assert first.def[0].sseq[3].dt.uns[0].text == 'often used before another noun '
	}
	{
		junk := mw.parse_response(load('testdata/learners/junk.json')) ?

		assert junk.len == 8
		assert junk[4].meta.app_shortdef.def.len == 0
	}
	{
		entries := mw.parse_response(load('testdata/learners/accountability.json')) ?

		assert entries.len == 1

		entry := entries[0]

		assert entry.uros.len == 1
		assert entry.uros[0].ure == 'ac*count*abil*i*ty'
		assert entry.uros[0].prs.len == 1
		assert entry.uros[0].fl == 'noun'
		assert entry.uros[0].ins.len == 0
		assert entry.uros[0].utxt.vis.len == 2
		assert entry.uros[0].gram == 'noncount'
	}
	{
		entries := mw.parse_response(load('testdata/learners/go_through.json')) ?
		entry := entries.filter(it.dros.len > 0).filter(it.dros[0].drp == 'go through')

		assert entry.len == 1
	}
}

fn load(testfile string) string {
	return os.read_file('./dictionary/mw/$testfile') or { panic(err) }
}

