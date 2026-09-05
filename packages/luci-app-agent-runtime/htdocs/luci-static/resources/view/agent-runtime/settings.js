'use strict';
'require form';
'require view';

function absolutePath(value) {
	return /^\/(?!.*(?:\/\/|\.\.))/.test(value || '');
}

return view.extend({
	render: function() {
		var map = new form.Map('agent-runtime', _('Agent Runtime configuration / 智能体运行环境配置'),
			_('These values describe local paths and an optional credential-free signed release endpoint. They do not install a runtime by themselves. / 此处只描述本地路径与可选签名发布端点，不会自行安装运行时。'));
		var section = map.section(form.NamedSection, 'main', 'agent_runtime');
		section.anonymous = true;

		var enabled = section.option(form.Flag, 'enabled', _('Enable boot status reconciliation / 启用启动状态对账'));
		enabled.default = enabled.enabled;

		[ [ 'data_root', '/data', _('Data root / 数据根目录') ],
		  [ 'runtime_root', '/data/agent-runtime', _('Runtime root / 运行时根目录') ],
		  [ 'baseline_root', '/opt/agent-runtime', _('Baseline root / 固件基线路径') ],
		  [ 'public_key', '/etc/agent-runtime/usign.pub', _('usign public key / usign 公钥') ]
		].forEach(function(item) {
			var option = section.option(form.Value, item[0], item[2]);
			option.default = item[1];
			option.validate = function(_section, value) {
				return absolutePath(value) ? true : _('Use an absolute path without ".." or double slashes.');
			};
		});

		var release = section.option(form.Value, 'release_url', _('Signed release base URL / 签名发布基础 URL'));
		release.placeholder = 'https://example.invalid/agent-runtime';
		release.rmempty = true;
		release.validate = function(_section, value) {
			return !value || (/^https:\/\/[A-Za-z0-9.-]+(?:\/[A-Za-z0-9._/-]*)?$/.test(value) && value.indexOf('..') < 0)
				? true : _('Use a credential-free HTTPS base URL.');
		};

		return map.render();
	}
});
