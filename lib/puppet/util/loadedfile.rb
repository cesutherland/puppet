require 'puppet'

module Puppet
  class NoSuchFile < Puppet::Error; end
  # A simple class that tells us when a file has changed and thus whether we
  # should reload it
  class Util::LoadedFile
    attr_reader :file, :statted

    # Provides a hook for setting the timestamp during testing, so we don't
    # have to depend on the granularity of the filesystem.
    attr_writer :tstamp

    # Determines whether the file has changed and thus whether it should
    # be reparsed.
    #
    def changed?
      # Allow the timeout to be disabled entirely.
      return true if Puppet[:filetimeout] < 0
      tmp = stamp

      # We use a different internal variable than the stamp method
      # because it doesn't keep historical state and we do -- that is,
      # we will always be comparing two timestamps, whereas
      # stamp just always wants the latest one.
      if tmp == @tstamp
        return false
      else
        @tstamp = tmp
        return @tstamp
      end
    end

    # Creates the file.
    # Must be passed the file path.
    # @param file [String] the path to watch
    # @param always_stale [Boolean] whether the file should be considered to always be changed
    # 
    def initialize(file)
      @file = file
      @statted = 0
      @stamp = nil
      @tstamp = stamp
    end

    # Retrieves the filestamp, but only refresh it if we're beyond our
    # filetimeout
    def stamp
      if @stamp.nil? or (Time.now.to_i - @statted >= Puppet[:filetimeout])
        @statted = Time.now.to_i
        begin
          @stamp = File.stat(@file).ctime
        rescue Errno::ENOENT, Errno::ENOTDIR
          @stamp = Time.now
        end
      end
      @stamp
    end

    def to_s
      @file
    end
  end
end

