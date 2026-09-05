'use strict';

/*
 * rpcd runs this plugin as root. The public API is deliberately a fixed
 * allow-list: callers cannot pass commands, paths, URLs, package names or
 * service names to any execve() call.
 */
let fs = require('fs');

const RUNTIME = '/usr/sbin/agent-runtime';
const JOB_HELPER = '/usr/libexec/agent-runtime-rpcd-job';
const JOB_ROOT = '/tmp/agent-runtime-rpcd-jobs/';
const MAX_OUTPUT = 16384;

function trim_output(value) {
	value = value || '';
	return length(value) > MAX_OUTPUT ? value.slice(-MAX_OUTPUT) : value;
}

function valid_id(value) {
	return type(value) == 'string' &&
		length(value) > 0 && length(value) <= 128 &&
		value.match(/^[A-Za-z0-9][A-Za-z0-9._-]*$/) &&
		index(value, '..') < 0;
}

function run_now(action) {
	let proc = fs.popen([ RUNTIME, action, '--json' ], 'r');
	if (!proc)
		return { ok: false, code: 'runtime_unavailable', message: 'agent-runtime is unavailable' };

	let output = proc.read('all') || '';
	let exit_code = proc.close();
	return {
		ok: exit_code == 0,
		code: exit_code == 0 ? 'ok' : 'runtime_failed',
		message: exit_code == 0 ? 'completed' : 'agent-runtime returned an error',
		exit_code: exit_code,
		output: trim_output(output)
	};
}

function start_job(action) {
	let proc = fs.popen([ JOB_HELPER, action ], 'r');
	if (!proc)
		return { ok: false, code: 'job_unavailable', message: 'unable to create background job' };

	let job_id = (proc.read('line') || '').trim();
	let exit_code = proc.close();
	if (exit_code != 0 || !valid_id(job_id))
		return { ok: false, code: 'job_unavailable', message: 'unable to create background job' };

	return { ok: true, code: 'queued', message: 'operation queued', job_id: job_id };
}

function get_job(request) {
	let job_id = request.args.job_id;
	if (!valid_id(job_id))
		return { ok: false, code: 'invalid_job', message: 'invalid job identifier' };

	let state = (fs.readfile(JOB_ROOT + job_id + '/state', 64) || 'missing').trim();
	let exit_code = (fs.readfile(JOB_ROOT + job_id + '/exit_code', 16) || '').trim();
	let output = fs.readfile(JOB_ROOT + job_id + '/result', MAX_OUTPUT) || '';
	return {
		ok: state != 'missing',
		code: state == 'missing' ? 'not_found' : 'ok',
		message: state == 'missing' ? 'job not found' : 'job status',
		data: { job_id: job_id, state: state, exit_code: exit_code, output: trim_output(output) }
	};
}

return {
	'agent-runtime': {
		status: { call: function() { return run_now('status'); } },
		list: { call: function() { return run_now('list'); } },
		check: { call: function() { return start_job('check'); } },
		verify: { call: function() { return start_job('verify'); } },
		reconcile: { call: function() { return start_job('reconcile'); } },
		job_status: { args: { job_id: '' }, call: get_job }
	}
};
