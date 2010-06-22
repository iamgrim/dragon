# encoding: utf-8
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'tzinfo'

require 'strscan'
require 'extensions'

require 'talker/talker_base'
require 'talker/telnet_connection'

EM.run {
  TalkerBase.instance.run
  EM.start_unix_domain_server("socket", TelnetConnection)
}