# frozen_string_literal: true

Puppet::Type.type(:filepath).provide(:posix, parent: Puppet::Type.type(:file).provider(:posix)) do
  def create
    mode = @resource.should(:mode)
    mkdir_r(@resource[:path], mode, @resource[:managedepth])
    @resource.send(:property_fix)
    :directory_created
  end

  def update
    true
  end

  def destroy
    true
  end

  def owner=(should)
    File.send(:chown, should, nil, resource[:path])
  rescue StandardError => detail
    raise Puppet::Error, _("Failed to set owner to '%{should}': %{detail}") % { should: should, detail: detail }, detail.backtrace
  end

  def group=(should)
    File.send(:chown, nil, should, resource[:path])
  rescue StandardError => detail
    raise Puppet::Error, _("Failed to set group to '%{should}': %{detail}") % { should: should, detail: detail }, detail.backtrace
  end

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
end
