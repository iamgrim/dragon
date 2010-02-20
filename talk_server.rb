# encoding: utf-8
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'tzinfo'

require 'strscan'
require 'extensions'

require 'talker/talker'
require 'talker/telnet_connection'

EM.run {
  Talker.instance.run
  EM.start_unix_domain_server("socket", TelnetConnection)
}