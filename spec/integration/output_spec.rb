require 'spec_helper'
require 'fileutils'

describe 'Buildpack packager output' do
  let(:buildpack_type) { '--uncached' }
  let(:buildpack_fixture) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'buildpack') }
  let(:tmpdir) { Dir.mktmpdir }

  before do
    FileUtils.rm_rf(tmpdir)
  end

  def buildpack_packager_execute(buildpack_dir, home_dir)
    Dir.chdir(buildpack_dir) do
      `HOME=#{home_dir} buildpack-packager #{buildpack_type}`
    end
  end

  subject { buildpack_packager_execute(buildpack_fixture, tmpdir) }

  context 'building the uncached buildpack' do
    it 'outputs the type of buildpack created, where and its human readable size' do
      expect(subject).to include("Uncached buildpack created and saved as")
      expect(subject).to include("spec/fixtures/buildpack/go_buildpack-v1.7.8.zip")
      expect(subject).to match(/with a size of 4\.0K$/)
    end
  end

  context 'building the cached buildpack' do
    let(:buildpack_type) { '--cached' }

    it 'outputs the dependencies downloaded, their versions, and download source url' do
      expect(subject).to include(<<-HEREDOC)
Downloading go version 1.6.3 from: https://buildpacks.cloudfoundry.org/concourse-binaries/go/go1.6.3.linux-amd64.tar.gz
  Using go version 1.6.3 with size 65M
  go version 1.6.3 matches the manifest provided md5 checksum of 5f7bf9d61d2b0dd75c9e2cd7a87272cc

Downloading godep version v74 from: https://pivotal-buildpacks.s3.amazonaws.com/concourse-binaries/godep/godep-v74-linux-x64.tgz
  Using godep version v74 with size 2.8M
  godep version v74 matches the manifest provided md5 checksum of 70220eee9f9e654e0b85887f696b6add
      HEREDOC
    end

    it 'outputs the type of buildpack created, where and its human readable size' do
      expect(subject).to include("Cached buildpack created and saved as")
      expect(subject).to include("spec/fixtures/buildpack/go_buildpack-cached-v1.7.8.zip")
      expect(subject).to match(/with a size of 68M$/)
    end

    context 'with a buildpack packager dependency cache intact' do
      before { buildpack_packager_execute(buildpack_fixture, tmpdir) }

      it 'outputs the dependencies downloaded, their versions, and cache location' do
        expect(subject).to include(<<-HEREDOC)
Using go version 1.6.3 from local cache at: #{tmpdir}/.buildpack-packager/cache/https___buildpacks.cloudfoundry.org_concourse-binaries_go_go1.6.3.linux-amd64.tar.gz with size 65M
  go version 1.6.3 matches the manifest provided md5 checksum of 5f7bf9d61d2b0dd75c9e2cd7a87272cc

Using godep version v74 from local cache at: #{tmpdir}/.buildpack-packager/cache/https___pivotal-buildpacks.s3.amazonaws.com_concourse-binaries_godep_godep-v74-linux-x64.tgz with size 2.8M
  godep version v74 matches the manifest provided md5 checksum of 70220eee9f9e654e0b85887f696b6add
        HEREDOC
      end
    end
  end
end
