# frozen_string_literal: true

# Puppetlabs Beaker acceptance testing harness
#
# Use for doing 'real-world' testing of the module, to ensure it can actually build on real machines
# and does what you expect it to.
#
# This is intended to be run with the included Rakefile. `rake -T` will show all tasks.
#
# There are also a few options that can be set through environment variables:
#
# BEAKER_debug (yes|no) - debug output from Beaker (including more verbose Puppet execution)
# BEAKER_destroy (yes|no) - destroy SUTs on test suite completion
# BEAKER_provision (yes|no) - provision new SUTs for tests or reuse existing
# BEAKER_puppet_debug (yes|no) - run Puppet with the `--debug --verbose` flags
# BEAKER_puppet_version - set the version of Puppet to be installed on the SUTs (systems under test)
#
require 'beaker-puppet'
require 'beaker-rspec'
require 'puppet'

# TODO: no windows support as of yet
UNSUPPORTED_PLATFORMS = ['windows'].freeze

# default to the puppet gem versions installed
PUPPET_VER = (ENV['BEAKER_puppet_version'] || Puppet.version).freeze

# autorequire shared serverspec examples
base_spec_dir = Pathname.new(File.join(File.dirname(__FILE__)))

Dir[base_spec_dir.join('shared/**/*.rb')].sort.each { |f| require f }

# pluginsync custom facts for all modules
#
# @param [Host, String, Symbol] host The test machine to run pluginsync on or a role (String or Symbol) that identifies a host
def pluginsync_on(hosts)
  pluginsync_manifest = <<-PLUGINSYNC_MANIFEST
    file { $::settings::libdir:
      ensure  => directory,
      source  => 'puppet:///plugins',
      recurse => true,
      purge   => true,
      backup  => false,
      noop    => false
    }
    PLUGINSYNC_MANIFEST
  apply_manifest_on(hosts, pluginsync_manifest)
end

unless ENV['RS_PROVISION'] == 'no' || ENV['BEAKER_provision'] == 'no'
  puppet_collection = case PUPPET_VER
                      when %r{^5}
                        'puppet5'
                      when %r{^6}
                        'puppet6'
                      else
                        nil
                      end

  install_puppet_on(
    hosts,
    version: PUPPET_VER,
    puppet_collection: puppet_collection,
  )
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      # install all modules from the fixtures directory
      copy_module_to(
        host,
        source: proj_root.to_s,
        module_name: 'filepath',
      )
      pluginsync_on(host)
    end
  end
end
