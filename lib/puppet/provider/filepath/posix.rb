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
  end

  def update
    @resource.send(:property_fix)
  end

  def destroy
    rmdir_r(@resource[:path], @resource[:managedepth])
  end

  def owner=(should)
    owner_r(@resource[:path], should, @resource[:managedepth])
  end

  def group=(should)
    group_r(@resource[:path], should, @resource[:managedepth])
  end

  def mode=(should)
    mode_r(@resource[:path], should, @resource[:managedepth])
  end

  private

  def mkdir(path, mode = nil, managedepth = 0)
    if mode && managedepth >= 1
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
    begin
      Dir.rmdir(path)
    rescue Errno::ENOTEMPTY
      raise Puppet::Error, "Cannot delete #{path}, it is not empty"
    end
    rmdir_r(File.dirname(path), managedepth - 1)
  end

  def owner_r(path, should, managedepth)
    return if managedepth < 1 || path == '/'
    parent = File.dirname(path)
    owner_r(parent, should, managedepth - 1)
    begin
      File.send(:chown, should, nil, path)
    rescue StandardError => detail
      raise Puppet::Error, "Failed to set owner to '#{should}': #{detail}", detail.backtrace
    end
  end

  def group_r(path, should, managedepth)
    return if managedepth < 1 || path == '/'
    parent = File.dirname(path)
    group_r(parent, should, managedepth - 1)
    begin
      File.send(:chown, nil, should, path)
    rescue StandardError => detail
      raise Puppet::Error, "Failed to set group to '#{should}': #{detail}", detail.backtrace
    end
  end

  def mode_r(path, should, managedepth)
    return if managedepth < 1 || path == '/'
    parent = File.dirname(path)
    mode_r(parent, should, managedepth - 1)
    begin
      File.chmod(should.to_i(8), path)
    rescue => detail
      raise Puppet::Error, "failed to set mode #{mode} on #{path}: #{detail}", detail.backtrace
    end
  end
end
