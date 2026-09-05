'use strict';
'require dom';
'require poll';
'require rpc';
'require ui';
'require view';

var callStatus = rpc.declare({ object: 'agent-runtime', method: 'status' });
var callList = rpc.declare({ object: 'agent-runtime', method: 'list' });
var callJobStatus = rpc.declare({ object: 'agent-runtime', method: 'job_status', params: [ 'job_id' ] });
var actions = {};

[ 'check', 'verify', 'reconcile' ].forEach(function(action) {
	actions[action] = rpc.declare({ object: 'agent-runtime', method: action });
});

function parseOutput(reply) {
	if (!reply || !reply.output)
		return null;
	try {
		return JSON.parse(reply.output);
	}
	catch (e) {
		return null;
	}
}

function text(value) {
	if (value === null || value === undefined || value === '')
		return '—';
	return String(value);
}

function state(value) {
	return value ? _('Ready / 已就绪') : _('Unavailable / 不可用');
}

function card(label, value, detail, healthy) {
	return E('div', {
		'class': 'cbi-value',
		'style': 'min-width:12rem; flex:1; margin:.35rem; padding:.9rem; border:1px solid var(--border-color-medium, #d8d8d8); border-radius:.45rem;'
	}, [
		E('div', { 'style': 'font-size:.8rem; opacity:.75; text-transform:uppercase;' }, label),
		E('div', { 'style': 'font-size:1.1rem; font-weight:600; color:' + (healthy ? 'var(--success-color, #2f855a)' : 'var(--error-color, #b91c1c)') + ';' }, value),
		E('div', { 'style': 'font-size:.8rem; opacity:.7; overflow-wrap:anywhere;' }, detail || ' ')
	]);
}

return view.extend({
	load: function() {
		return Promise.all([ callStatus(), callList() ]);
	},

	render: function(data) {
		var self = this;
		var summary = E('div', { 'class': 'cbi-section', 'style': 'display:flex; flex-wrap:wrap; padding:.4rem;' });
		var integrations = E('div', { 'class': 'cbi-section' });
		var generations = E('div', { 'class': 'cbi-section' });
		var jobBox = E('pre', {
			'class': 'agent-runtime-log',
			'style': 'max-height:18rem; overflow:auto; white-space:pre-wrap; word-break:break-word;'
		}, _('No operation is running. / 当前没有运行任务。'));
		var currentJob = null;

		function showStatus(statusReply, listReply) {
			var parsed = parseOutput(statusReply) || {};
			var payload = parsed.data || {};
			var storage = payload.storage || {};
			var runtime = payload.runtime || {};
			var release = payload.release || {};
			var integration = payload.integrations || {};
			var listed = (parseOutput(listReply) || {}).data || {};
			var configured = !!release.configured && !!release.public_key_present;

			dom.content(summary, [
				card(_('Storage / 数据盘'), state(storage.mounted && storage.writable), text(storage.path), storage.mounted && storage.writable),
				card(_('Runtime baseline / 固件基线'), state(runtime.baseline_present), text(runtime.active || _('No active generation')), runtime.baseline_present),
				card(_('Signed release / 签名发布'), state(configured), configured ? _('HTTPS + usign configured') : _('Configure URL and public key'), configured),
				card(_('Generations / 版本代'), String((runtime.generations || []).length), text(runtime.previous || _('No previous generation')), true)
			]);

			dom.content(integrations, [
				E('h3', {}, _('Optional integrations / 可选集成')),
				E('table', { 'class': 'table cbi-section-table' }, [
					[ _('Node.js'), text(integration.node) ],
					[ _('Pi'), text(integration.pi) ],
					[ _('CommandCode'), text(integration.cmdc) ],
					[ _('Multica'), text(integration.multica) ]
				].map(function(row) { return E('tr', {}, [ E('th', {}, row[0]), E('td', {}, row[1]) ]); }))
			]);

			dom.content(generations, [
				E('h3', {}, _('Installed generations / 已发现版本代')),
				E('pre', { 'style': 'white-space:pre-wrap; word-break:break-word;' },
					JSON.stringify(listed.generations || runtime.generations || [], null, 2))
			]);
		}

		function refresh() {
			return Promise.all([ callStatus(), callList() ]).then(function(replies) {
				showStatus(replies[0], replies[1]);
			}).catch(function(err) {
				dom.content(summary, E('p', { 'class': 'alert-message warning' }, String(err)));
			});
		}

		function showJob(reply) {
			if (!reply || !reply.data) {
				dom.content(jobBox, _('Unable to read job status. / 无法读取任务状态。'));
				return;
			}
			var job = reply.data;
			dom.content(jobBox, [
				_('Job: %s\nState: %s\nExit code: %s\n\n').format(job.job_id, job.state, text(job.exit_code)),
				job.output || _('Waiting for command output…')
			]);
			if (job.state === 'completed')
				refresh();
		}

		function queue(action) {
			return actions[action]().then(function(reply) {
				if (!reply || !reply.ok) {
					ui.addNotification(null, E('p', {}, reply ? reply.message : _('Operation was rejected.')), 'danger');
					return;
				}
				currentJob = reply.job_id;
				dom.content(jobBox, _('Queued %s (job %s)…').format(action, currentJob));
			}).catch(function(err) {
				ui.addNotification(null, E('p', {}, String(err)), 'danger');
			});
		}

		var buttons = [
			[ 'check', _('Check signed release / 检查签名发布'), 'cbi-button-action important' ],
			[ 'verify', _('Verify active manifest / 验证当前清单'), 'cbi-button-neutral' ],
			[ 'reconcile', _('Refresh local status / 刷新本机状态'), 'cbi-button-neutral' ]
		].map(function(item) {
			return E('button', {
				'class': 'cbi-button ' + item[2],
				'click': ui.createHandlerFn(self, function() { return queue(item[0]); })
			}, item[1]);
		});

		poll.add(function() {
			var requests = [ refresh() ];
			if (currentJob)
				requests.push(callJobStatus(currentJob).then(showJob));
			return Promise.all(requests);
		}, 5);

		showStatus(data[0], data[1]);
		return E([], [
			E('h2', {}, _('Agent Runtime / 智能体运行环境')),
			E('p', { 'class': 'cbi-section-descr' },
				_('A local, restricted control surface. It never provides a web shell or installs unsigned payloads. / 本页面不提供 Web Shell，也不会安装未签名载荷。')),
			summary,
			E('div', { 'class': 'cbi-section' }, buttons),
			integrations,
			generations,
			E('h3', {}, _('Operation log / 操作日志')),
			jobBox
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
