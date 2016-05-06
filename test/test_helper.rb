$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dendrite'

Dendrite::Config.load(source: 'conf/config.yaml')
require 'minitest/autorun'
