require 'spec_helper_acceptance'

hosts.each do |host|
  describe 'filepath', "on #{host}" do
    let(:manifest) do
      <<-MANIFEST
      filepath { '/app/test/filepath':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0777',
        managedepth => 3,
      }
      MANIFEST
    end

    it 'applies without errors' do
      apply_manifest_on(host, manifest, catch_failures: true, verbose: true)
    end
  end
end
