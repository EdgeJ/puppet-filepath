# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/filepath'

describe Puppet::Type.type(:filepath) do
  let(:resource) do
    Puppet::Type.type(:filepath).new(
      name: '/path/to/dir',
      ensure: 'present',
      owner: 'foo',
      group: 'foo',
      mode: '0770',
    )
  end

  it 'accepts a directory name as the path parameter' do
    expect(resource[:path]).to eq('/path/to/dir')
  end

  ['owner', 'group'].each do |property|
    it "accepts #{property}" do
      expect(resource[property.to_sym]).to eq('foo')
    end
  end

  it 'accepts filemode' do
    expect(resource[:mode]).to eq('0770')
  end

  it 'expects a name' do
    expect { described_class.new({}) }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
end
