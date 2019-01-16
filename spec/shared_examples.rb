# rubocop:disable RSpec/BeforeAfterAll
shared_examples 'creates_file' do |test_node, manifest, test_dir, owner, group|
  base_dir = "/#{test_dir.split('/')[1]}"
  before(:all) { on(test_node, "rm -rf #{base_dir}") }

  it 'applies with no errors' do
    apply_manifest_on(test_node, manifest, catch_failures: true, verbose: true)
  end

  it 'applies a second time with no changes' do
    apply_manifest_on(test_node, manifest, catch_changes: true)
  end

  it 'provisions the directory', node: test_node do
    expect(file(test_dir)).to be_directory
  end

  it 'is owned by the correct user and group', node: test_node do
    expect(file(test_dir)).to be_owned_by(owner)
    expect(file(test_dir)).to be_grouped_into(group)
  end
end

shared_examples 'deletes_file' do |test_node, manifest, test_dir|
  before(:all) { on(test_node, "mkdir -p #{test_dir}") }

  it 'applies with no errors' do
    apply_manifest_on(test_node, manifest, catch_failures: true, verbose: true)
  end

  it 'applies a second time with no changes' do
    apply_manifest_on(test_node, manifest, catch_changes: true)
  end

  it 'deletes the directory', node: test_node do
    expect(file(test_dir)).not_to exist
  end
end
# rubocop:enable RSpec/BeforeAll
