require 'rubygems'
require 'bundler/setup'
require 'haml'
require 'yaml'

palette = YAML.load(File.new('palette.yml'))
settings = YAML.load(File.new('settings.yml'))
settings['colors'] = settings['colors'].map{|k, v| {k => palette[v]}}.inject({}, &:merge)

def explode(opts)
  (opts || {}).map { |k, vs| (vs || '').split(' ').map { |v| {v => k} } }.flatten.inject({}, &:merge)
end

options = []
YAML.load(File.new('languages.yml')).each do |prefix, lang|
  foreground = explode(lang['foreground'])
  background = explode(lang['background'])

  lang['keys'].split(' ').each do |key|
    options << {
        name: "#{prefix}#{key}",
        value: {
            'FOREGROUND' => palette[foreground[key]],
            'BACKGROUND' => palette[background[key]],
            'FONT_TYPE' => 0,
            'EFFECT_COLOR' => nil,
            'EFFECT_TYPE' => 0,
            'ERROR_STRIPE_COLOR' => nil
        }
    }
  end
end
options.sort_by!{|o| o[:name]}

engine = Haml::Engine.new(File.read('template.haml'), {
    autoclose: %w(option),
    attr_wrapper: '"'
})
File.open('../Quiet.xml', 'w') do |f|
  f.write(engine.render(Object.new, {
      settings: settings,
      options: options
  }))
end
