# Try to load rubygems.  Hey rubygems, I hate you.
begin
  require 'rubygems'
rescue LoadError
end

# see the bottom of the file for further inclusions
require 'singleton'
require 'facter'
require 'puppet/error'
require 'puppet/util'
require 'puppet/util/autoload'
require 'puppet/util/settings'
require 'puppet/util/feature'
require 'puppet/util/suidmanager'
require 'puppet/util/run_mode'

#------------------------------------------------------------
# the top-level module
#
# all this really does is dictate how the whole system behaves, through
# preferences for things like debugging
#
# it's also a place to find top-level commands like 'debug'

module Puppet
  PUPPETVERSION = '2.7.12'

  def Puppet.version
    PUPPETVERSION
  end

  class << self
    include Puppet::Util
    attr_reader :features
    attr_writer :name
  end

  # the hash that determines how our system behaves
  @@settings = Puppet::Util::Settings.new

  # The services running in this process.
  @services ||= []

  require 'puppet/util/logging'

  extend Puppet::Util::Logging

  # The feature collection
  @features = Puppet::Util::Feature.new('puppet/feature')

  # Load the base features.
  require 'puppet/feature/base'

  # Store a new default value.
  def self.define_settings(section, hash)
    @@settings.define_settings(section, hash)
  end

  # configuration parameter access and stuff
  def self.[](param)
    if param == :debug
      return Puppet::Util::Log.level == :debug
    else
      return @@settings[param]
    end
  end

  # configuration parameter access and stuff
  def self.[]=(param,value)
    @@settings[param] = value
  end

  def self.clear
    @@settings.clear
  end

  def self.debug=(value)
    if value
      Puppet::Util::Log.level=(:debug)
    else
      Puppet::Util::Log.level=(:notice)
    end
  end

  def self.settings
    @@settings
  end


  # TODO cprice: document; would like to get rid of this but it's just used in too many places right now.
  def self.run_mode
    #$puppet_application_mode || Puppet::Util::RunMode[:user]
    Puppet::Util::RunMode[@@settings.run_mode]
  end

  # TODO cprice: experimenting with getting rid of these
  #def self.application_name
  #  $puppet_application_name ||= "apply"
  #end

  # Load all of the configuration parameters.
  require 'puppet/defaults'

  def self.genmanifest
    if Puppet[:genmanifest]
      puts Puppet.settings.to_manifest
      exit(0)
    end
  end

  # Parse the config file for this process.
  def self.parse_config
    Puppet.settings.parse
  end

  # Create a new type.  Just proxy to the Type class.  The mirroring query
  # code was deprecated in 2008, but this is still in heavy use.  I suppose
  # this can count as a soft deprecation for the next dev. --daniel 2011-04-12
  def self.newtype(name, options = {}, &block)
    Puppet::Type.newtype(name, options, &block)
  end
end

# This feels weird to me; I would really like for us to get to a state where there is never a "require" statement
#  anywhere besides the very top of a file.  That would not be possible at the moment without a great deal of
#  effort, but I think we should strive for it and revisit this at some point.  --cprice 2012-03-16

require 'puppet/type'
require 'puppet/parser'
require 'puppet/resource'
require 'puppet/network'
require 'puppet/ssl'
require 'puppet/module'
require 'puppet/util/storage'
require 'puppet/status'
require 'puppet/file_bucket/file'
