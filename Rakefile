# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name = 'romote'
  app.icon = 'romote.icns'
  app.vendor_project('vendor/CocoaAsyncSocket', :static, :headers_dir => '.', :cflags => '-fobjc-arc')
end
