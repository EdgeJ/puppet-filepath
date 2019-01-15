# frozen_string_literal: true

Puppet::Type.type(:filepath).provide(:posix, parent: Puppet::Type.type(:file).provider(:posix)) do
  require 'puppet/util/symbolic_file_mode'
  include Puppet::Util::SymbolicFileMode

  def exists?
    !@resource.stat.nil?
  end

  def create
    mode = @resource.should(:mode)
    mkdir_r(@resource[:path], mode, @resource[:managedepth])
    @resource.send(:property_fix)
    :directory_created
  end

  def update
    @resource.send(:property_fix)
  end

  def destroy
    rmdir_r(@resource[:path], @resource[:managedepth])
  end

  def owner=(should)
    File.send(:chown, should, nil, resource[:path])
  rescue StandardError => detail
    raise Puppet::Error, "Failed to set owner to '#{should}': #{detail}", detail.backtrace
  end

  def group=(should)
    File.send(:chown, nil, should, resource[:path])
  rescue StandardError => detail
    raise Puppet::Error, "Failed to set group to '#{should}': #{detail}", detail.backtrace
  end

  private

  def mkdir(path, mode = nil, managedepth = 0)
    if mode && !managedepth.zero?
      Puppet::Util.withumask(0o00) do
        Dir.mkdir(path, symbolic_mode_to_int(mode, 0o755, true))
      end
    else
      Dir.mkdir(path)
    end
  end

  def mkdir_r(path, mode = nil, managedepth = 0)
    parent = File.dirname(path)
    unless Puppet::FileSystem.exist?(parent) || parent == '/'
      mkdir_r(parent, mode, managedepth - 1)
    end
    mkdir(path, mode, managedepth)
  end

  def rmdir_r(path, managedepth)
    return unless managedepth >= 1
    raise Puppet::Error, 'Refusing to delete /' if path == '/'
    Dir.rmdir(path)
    rmdir_r(File.dirname(path), managedepth - 1)
  end
end
