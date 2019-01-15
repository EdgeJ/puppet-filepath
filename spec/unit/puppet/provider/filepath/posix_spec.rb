# frozen_string_literal: true

require 'spec_helper'
require 'puppet/provider/filepath/posix'

def tempdir
  @tempdir ||= Dir.mktmpdir
end

def cleantempdir
  Dir.rmdir tempdir
rescue Errno::ENOENT
  return
end

# rubocop:disable RSpec/InstanceVariable
describe Puppet::Type.type(:filepath).provider(:posix) do
  let(:path) { tempdir }

  let(:resource) do
    Puppet::Type.type(:filepath).new(
      path: path,
      ensure: 'present',
      owner: 'foo',
      group: 'foo',
      mode: '0770',
      provider: described_class.name,
    )
  end

  let(:provider) { resource.provider }
  let(:passwd) { Struct::Passwd.new('foo', nil, 502, 502) }

  after(:each) { cleantempdir }

  describe '#create' do
    it 'creates the resource' do
      allow(Etc).to receive(:getgrnam).with('foo').and_return(passwd)
      allow(Etc).to receive(:getgrgid).with(502).and_return(passwd)
      allow(Etc).to receive(:getpwnam).with('foo').and_return(passwd)
      allow(Etc).to receive(:getpwuid).with(502).and_return(passwd)

      allow(File).to receive(:chown).with(502, nil, path)
      allow(File).to receive(:chown).with(nil, 502, path)

      expect(Dir).to receive(:mkdir)

      provider.create
    end
  end

  describe '#update' do
    it 'updates the resource' do
      allow(Etc).to receive(:getgrnam).with('foo').and_return(passwd)
      allow(Etc).to receive(:getgrgid).with(502).and_return(passwd)
      allow(Etc).to receive(:getpwnam).with('foo').and_return(passwd)
      allow(Etc).to receive(:getpwuid).with(502).and_return(passwd)

      expect(File).to receive(:chown).with(502, nil, path)
      expect(File).to receive(:chown).with(nil, 502, path)

      provider.update
    end
  end

  describe '#destroy' do
    context 'with managedepth => 2' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/moog',
          ensure: 'present',
          managedepth: 2,
          provider: described_class.name,
        )
      end

      it 'deletes the resource 2 directories deep' do
        expect(Dir).to receive(:rmdir).with('/path/to/moog')
        expect(Dir).to receive(:rmdir).with('/path/to')
        expect(Dir).not_to receive(:rmdir).with('/path')

        provider.destroy
      end
    end

    context 'with default managedepth' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/moog',
          ensure: 'present',
          provider: described_class.name,
        )
      end

      it 'deletes the resource 1 directories deep' do
        expect(Dir).to receive(:rmdir).with('/path/to/moog')
        expect(Dir).not_to receive(:rmdir).with('/path/to')
        expect(Dir).not_to receive(:rmdir).with('/path')

        provider.destroy
      end
    end
  end

  describe '#mode' do
    it 'return a string with the higher-order bits stripped away' do
      FileUtils.touch(path)
      File.chmod(0o644, path)

      expect(provider.mode).to eq('0644')
    end

    context 'when file doesn\'t exist' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/nonexistent/dir',
          ensure: 'present',
          owner: 'foo',
          group: 'foo',
          mode: '0770',
          provider: described_class.name,
        )
      end

      let(:provider) { resource.provider }

      it 'return absent' do
        expect(provider.mode).to eq(:absent)
      end
    end
  end

  describe '#mode=' do
    it 'chmod the file to the specified value' do
      FileUtils.touch(path)
      File.chmod(0o644, path)

      provider.mode = '0755'

      expect(provider.mode).to eq('0755')
    end

    context 'when file doesn\'t exist' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/nonexistent/dir',
          ensure: 'present',
          owner: 'foo',
          group: 'foo',
          mode: '0770',
          provider: described_class.name,
        )
      end

      let(:provider) { resource.provider }

      it 'pass along any errors encountered' do
        expect {
          provider.mode = '0644'
        }.to raise_error(Puppet::Error, %r{failed to set mode})
      end
    end
  end

  describe '#uid2name' do
    it 'return the name of the user identified by the id' do
      allow(Etc).to receive(:getpwuid).with(501).and_return(Struct::Passwd.new('jilluser', nil, 501))

      expect(provider.uid2name(501)).to eq('jilluser')
    end

    it "return the argument if it's already a name" do
      expect(provider.uid2name('jilluser')).to eq('jilluser')
    end

    it 'return nil if the argument is above the maximum uid' do
      expect(provider.uid2name(Puppet[:maximum_uid] + 1)).to eq(nil)
    end

    it "return nil if the user doesn't exist" do
      allow(Etc).to receive(:getpwuid).and_raise(ArgumentError, "can't find user for 999")

      expect(provider.uid2name(999)).to eq(nil)
    end
  end

  describe '#name2uid' do
    it 'return the id of the user if it exists' do
      passwd = Struct::Passwd.new('bobbo', nil, 502)

      allow(Etc).to receive(:getpwnam).with('bobbo').and_return(passwd)
      allow(Etc).to receive(:getpwuid).with(502).and_return(passwd)

      expect(provider.name2uid('bobbo')).to eq(502)
    end

    it "return the argument if it's already an id" do
      expect(provider.name2uid('503')).to eq(503)
    end

    it "return false if the user doesn't exist" do
      allow(Etc).to receive(:getpwnam).with('chuck').and_raise(ArgumentError, "can't find user for chuck")

      expect(provider.name2uid('chuck')).to eq(false)
    end
  end

  describe '#owner' do
    it 'return the uid of the file owner' do
      FileUtils.touch(path)
      owner = Puppet::FileSystem.stat(path).uid

      expect(provider.owner).to eq(owner)
    end

    context 'when file doesn\'t exist' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/nonexistent/dir',
          ensure: 'present',
          owner: 'foo',
          group: 'foo',
          mode: '0770',
          provider: described_class.name,
        )
      end

      let(:provider) { resource.provider }

      it 'return absent' do
        expect(provider.owner).to eq(:absent)
      end
    end

    it 'warn and return :silly if the value is beyond the maximum uid' do
      # rubocop:disable RSpec/VerifiedDoubles
      stat = double('stat', uid: Puppet[:maximum_uid] + 1)
      # rubocop:enable RSpec/VerifiedDoubles
      allow(resource).to receive(:stat).and_return(stat)

      expect(provider.owner).to eq(:silly)
      expect(@logs).to(be_any) { |log| log.level == :warning && log.message =~ %r{Apparently using negative UID} }
    end
  end

  describe '#owner=' do
    it 'set the owner but not the group of the file' do
      expect(File).to receive(:chown).with(15, nil, resource[:path])

      provider.owner = 15
    end

    it 'pass along any error encountered setting the owner' do
      allow(File).to receive(:chown).and_raise(ArgumentError)

      expect { provider.owner = 25 }.to raise_error(Puppet::Error, %r{Failed to set owner to '25'})
    end
  end

  describe '#gid2name' do
    it 'return the name of the group identified by the id' do
      allow(Etc).to receive(:getgrgid).with(501).and_return(Struct::Passwd.new('unicorns', nil, nil, 501))

      expect(provider.gid2name(501)).to eq('unicorns')
    end

    it "return the argument if it's already a name" do
      expect(provider.gid2name('leprechauns')).to eq('leprechauns')
    end

    it 'return nil if the argument is above the maximum gid' do
      expect(provider.gid2name(Puppet[:maximum_uid] + 1)).to eq(nil)
    end

    it "return nil if the group doesn't exist" do
      expect(Etc).to receive(:getgrgid).and_raise(ArgumentError, "can't find group for 999")

      expect(provider.gid2name(999)).to eq(nil)
    end
  end

  describe '#name2gid' do
    it 'return the id of the group if it exists' do
      passwd = Struct::Passwd.new('penguins', nil, nil, 502)

      allow(Etc).to receive(:getgrnam).with('penguins').and_return(passwd)
      allow(Etc).to receive(:getgrgid).with(502).and_return(passwd)

      expect(provider.name2gid('penguins')).to eq(502)
    end

    it "return the argument if it's already an id" do
      expect(provider.name2gid('503')).to eq(503)
    end

    it "return false if the group doesn't exist" do
      allow(Etc).to receive(:getgrnam).with('wombats').and_raise(ArgumentError, "can't find group for wombats")

      expect(provider.name2gid('wombats')).to eq(false)
    end
  end

  describe '#group' do
    it 'return the gid of the file group' do
      FileUtils.touch(path)
      group = Puppet::FileSystem.stat(path).gid

      expect(provider.group).to eq(group)
    end

    context 'when file doesn\'t exist' do
      let(:resource) do
        Puppet::Type.type(:filepath).new(
          path: '/path/to/nonexistent/dir',
          ensure: 'present',
          owner: 'foo',
          group: 'foo',
          mode: '0770',
          provider: described_class.name,
        )
      end

      let(:provider) { resource.provider }

      it 'return absent' do
        expect(provider.group).to eq(:absent)
      end
    end

    it 'warn and return :silly if the value is beyond the maximum gid' do
      # rubocop:disable RSpec/VerifiedDoubles
      stat = double('stat', gid: Puppet[:maximum_uid] + 1)
      # rubocop:enable RSpec/VerifiedDoubles
      allow(resource).to receive(:stat).and_return(stat)

      expect(provider.group).to eq(:silly)
      expect(@logs).to(be_any) { |log| log.level == :warning && log.message =~ %r{Apparently using negative GID} }
    end
  end

  describe '#group=' do
    it 'set the group but not the owner of the file' do
      expect(File).to receive(:chown).with(nil, 15, resource[:path])

      provider.group = 15
    end

    it 'pass along any error encountered setting the group' do
      expect(File).to receive(:chown).and_raise(ArgumentError)

      expect { provider.group = 25 }.to raise_error(Puppet::Error, %r{Failed to set group to '25'})
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
