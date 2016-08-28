$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dendrite'

Dendrite::Config.load(source: 'conf/config.yml')
require 'minitest/autorun'
