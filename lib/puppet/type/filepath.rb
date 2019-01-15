# frozen_string_literal: true

# @summary Recursively manage directory resources
#
# @note Much was ported from the native Puppet `file` type, however we don't
# need all of the functionality of the `file` type, so it's not used as the
# parent for this type
#
# @author John Edge <edge.jm@gmail.com>
Puppet::Type.newtype(:filepath) do
  @doc = <<-DOCSTRING
      This type provides Puppet with the capabilities to manage recursive directory filepaths, creating all directories in the specified filepath.
  DOCSTRING

  ensurable

  newparam(:path) do
    desc 'The fully qualified directory filepath you want to manage.'
    isnamevar

    validate do |value|
      raise Puppet::Error, _("File paths must be fully qualified, not '#{value}'") unless Puppet::Util.absolute_path?(value)
    end
  end

  newparam(:managedepth) do
    desc 'The number of directory levels to manage with users and permissions.'
    defaultto 1

    validate do |value|
      raise Puppet::Error, _("Managedepth must be integer, not '#{value}'") unless value.is_a?(Integer)
    end
  end

  # replicating group, mode, and owner properties from the file type
  newproperty(:group, parent: Puppet::Type::File::Group)

  newproperty(:mode, parent: Puppet::Type::File::Mode)

  newproperty(:owner, parent: Puppet::Type::File::Owner)

  # Autorequire the owner and group of the file.
  { user: :owner, group: :group }.each do |type, property|
    autorequire(type) do
      if @parameters.include?(property)
        # The user/group property automatically converts to IDs
        # rubocop:disable Lint/AssignmentInCondition
        next unless should = @parameters[property].shouldorig

        val = should[0]
        if val.is_a?(Integer) || val =~ %r{^\d+$}
          nil
        else
          val
        end
        # rubocop:enable Lint/AssignmentInCondition
      end
    end
  end

  def flush
    # We want to make sure we retrieve metadata anew on each transaction.
    @parameters.each do |_, param|
      param.flush if param.respond_to?(:flush)
    end
    @stat = :needs_stat
  end

  def initialize(hash)
    # Used for caching clients
    @clients = {}

    super

    @stat = :needs_stat
  end

  # Stat our file.
  #
  # We use the initial value :needs_stat to ensure we only stat the file once,
  # but can also keep track of a failed stat (@stat == nil). This also allows
  # us to re-stat on demand by setting @stat = :needs_stat.
  def stat
    return @stat unless @stat == :needs_stat

    method = :stat

    @stat = begin
              Puppet::FileSystem.send(method, self[:path])
            rescue Errno::ENOENT
              nil
            rescue Errno::ENOTDIR
              nil
            rescue Errno::EACCES
              warning _('Could not stat; permission denied')
              nil
            rescue Errno::EINVAL
              warning _('Could not stat; invalid pathname')
              nil
            end
  end

  # There are some cases where all of the work does not get done on
  # file creation/modification, so we have to do some extra checking.
  def property_fix
    properties.each do |thing|
      next unless [:mode, :owner, :group].include?(thing.name)

      # Make sure we get a new stat object
      @stat = :needs_stat
      currentvalue = thing.retrieve
      thing.sync unless thing.safe_insync?(currentvalue)
    end
  end
end
