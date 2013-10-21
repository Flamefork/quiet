require 'rubygems'
require 'bundler/setup'
require 'haml'
require 'yaml'

palette = YAML.load(File.new('palette.yml'))
settings = YAML.load(File.new('settings.yml'))
settings['colors'] = settings['colors'].map{|k, v| {k => palette[v]}}.inject({}, &:merge)

def explode(opts)
  (opts || {}).map do |k, vs|
    keys = (vs || '')
    keys = keys.split(/\s/) if keys.respond_to?(:split)
    keys.map { |v| {v => k} }
  end.flatten.inject({}, &:merge)
end

options = []
YAML.load(File.new('languages.yml')).each do |prefix, lang|
  foreground = explode(lang['foreground'])
  background = explode(lang['background'])

  keys = lang['keys']
  keys = keys.split(/\s/) if keys.respond_to?(:split)
  keys.each do |key|
    value = {}
    value['FOREGROUND'] = palette[foreground[key]] if palette[foreground[key]]
    value['BACKGROUND'] = palette[background[key]] if palette[background[key]]
    options << {
        name: "#{prefix}#{key}",
        value: value
    }
  end
end
options.sort_by!{|o| o[:name]}

engine = Haml::Engine.new(File.read('template.haml'), {
    autoclose: %w(option value),
    attr_wrapper: '"'
})
File.open('../Quiet.icls', 'w') do |f|
  f.write(engine.render(Object.new, {
      settings: settings,
      options: options
  }))
end
