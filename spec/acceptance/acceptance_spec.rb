require 'spec_helper_acceptance'

hosts.each do |host|
  describe 'filepath', "on #{host}" do
    let(:test_node) { host }

    context 'with ensure => present' do
      context 'with undefined user' do
        manifest = <<-MANIFEST
          filepath { '/app/test/filepath':
            ensure      => present,
            mode        => '0777',
            managedepth => 3,
          }
        MANIFEST

        it_behaves_like 'creates_file', host, manifest, '/app/test/filepath', 'root', 'root'
      end

      context 'with defined user' do
        manifest = <<-MANIFEST
          user { 'foo':
            ensure => present,
          }

          group { 'bar':
            ensure => present,
          }

          filepath { '/app/test/filepath':
            ensure      => present,
            owner       => 'foo',
            group       => 'bar',
            mode        => '0777',
            managedepth => 3,
          }
        MANIFEST

        it_behaves_like 'creates_file', host, manifest, '/app/test/filepath', 'foo', 'bar'
      end

      context 'with default managedepth' do
        manifest = <<-MANIFEST
          filepath { '/app/test/filepath':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0777',
          }
        MANIFEST

        it_behaves_like 'creates_file', host, manifest, '/app/test/filepath', 'root', 'root'
      end

      context 'with managedepth => 2 and directory three levels deep' do
        let(:pp) do
          <<-MANIFEST
            filepath { '/app/test/filepath':
              ensure => present,
              owner => 'foo',
              group => 'bar',
              mode => '0777',
              managedepth => 2,
            }

            user { 'foo':
              ensure => present,
            }

            group { 'bar':
              ensure => present,
            }
          MANIFEST
        end

        before(:each) { on(host, 'rm -rf /app') }

        it 'only manages two levels deep', node: host do
          apply_manifest_on(host, pp, catch_failures: true)
          expect(file('/app/test/filepath')).to be_owned_by('foo')
          expect(file('/app/test/filepath')).to be_mode(777)
          expect(file('/app/test')).to be_owned_by('foo')
          expect(file('/app/test')).to be_mode(777)
          expect(file('/app')).not_to be_owned_by('foo')
        end
      end

      context 'with managedepth => 2 and directory four levels deep' do
        let(:pp) do
          <<-MANIFEST
            filepath { '/app/test/filepath/foo':
              ensure => present,
              owner => 'foo',
              group => 'bar',
              mode => '0777',
              managedepth => 2,
            }

            user { 'foo':
              ensure => present,
            }

            group { 'bar':
              ensure => present,
            }
          MANIFEST
        end

        before(:each) { on(host, 'rm -rf /app') }

        it 'only manages two levels deep', node: host do
          apply_manifest_on(host, pp, catch_failures: true)
          expect(file('/app/test/filepath/foo')).to be_owned_by('foo')
          expect(file('/app/test/filepath')).to be_owned_by('foo')
          expect(file('/app/test')).not_to be_owned_by('foo')
          expect(file('/app')).not_to be_owned_by('foo')
        end
      end
    end

    context 'with ensure => absent' do
      manifest = <<-MANIFEST
        filepath { '/app/test/filepath':
          ensure      => absent,
          managedepth => 3,
        }
      MANIFEST

      it_behaves_like 'deletes_file', host, manifest, '/app/test/filepath'

      context 'with managedepth => 2 and directory three levels deep', node: host do
        let(:pp) { "filepath { '/app/test/filepath': ensure => absent, managedepth => 2, }" }

        before(:each) do
          on(host, 'rm -rf /app')
          on(host, 'mkdir -p /app/test/filepath')
        end

        it 'only deletes two levels deep' do
          apply_manifest_on(host, pp, catch_failures: true)
          expect(file('/app')).to be_directory
          expect(file('/app/test')).not_to exist
        end
      end

      context 'when attempting to delete /' do
        let(:pp) { "filepath { '/': ensure => absent, }" }

        it 'throws an error' do
          expect(
            apply_manifest_on(host, pp, expect_failures: true).stderr,
          ).to match(%r{Refusing to delete /})
        end
      end
    end
  end
end
