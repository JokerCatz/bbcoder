$:.unshift "#{File.dirname(__FILE__)}"
require 'bbcoder'
require 'bbcoder_helper'
ActionView::Base.send :include, BBCoderHelper
ActiveRecord::Base.send :include, BBCoder