require 'spec_helper'
require 'fileutils'

describe 'Buildpack packager output' do
  let(:buildpack_type)    { '--uncached' }
  let(:stack)             { '--any-stack' }
  let(:fixture_name)      { 'buildpack-without-uri-credentials' }
  let(:buildpack_fixture) { File.join(File.dirname(__FILE__), '..', 'fixtures', fixture_name) }
  let(:tmpdir)            { Dir.mktmpdir }

  before do
    FileUtils.rm_rf(tmpdir)
  end

  def buildpack_packager_execute(buildpack_dir, home_dir)
    Dir.chdir(buildpack_dir) do
      `HOME=#{home_dir} buildpack-packager #{buildpack_type} #{stack}`
    end
  end

  subject { buildpack_packager_execute(buildpack_fixture, tmpdir) }

  context 'building the uncached buildpack' do
    it 'outputs the type of buildpack created, where and its human readable size' do
      expect(subject).to include("Uncached buildpack for any stack created and saved as")
      expect(subject).to include("spec/fixtures/#{fixture_name}/go_buildpack-v1.7.8.zip")
      expect(subject).to match(/with a size of 4\.0K$/)
    end
  end

  context 'building the cached buildpack' do
    let(:buildpack_type) { '--cached' }

    it 'outputs the dependencies downloaded, their versions, and download source url' do
      expect(subject).to include("Downloading go version 1.6.3 from: https://buildpacks.cloudfoundry.org/concourse-binaries/go/go1.6.3.linux-amd64.tar.gz")
      expect(subject).to include("Using go version 1.6.3 with size")
      expect(subject).to include("go version 1.6.3 matches the manifest provided sha256 checksum of 5ac238cd321a66a35c646d61e4cafd922929af0800c78b00375312c76e702e11")

      expect(subject).to include("Downloading godep version v74 from: https://pivotal-buildpacks.s3.amazonaws.com/concourse-binaries/godep/godep-v74-linux-x64.tgz")
      expect(subject).to include("Using godep version v74 with size 2.8M")
      expect(subject).to include("godep version v74 matches the manifest provided sha256 checksum of 6e6761b71e1518bf7716b3f383f10598afe5ce4592e6eea0184f17b85fd93813")
    end

    it 'outputs the type of buildpack created, where and its human readable size' do
      expect(subject).to include("Cached buildpack for any stack created and saved as")
      expect(subject).to include("spec/fixtures/#{fixture_name}/go_buildpack-cached-v1.7.8.zip")
      expect(subject).to match(/with a size of [\d]+M$/)
    end

    context 'with a buildpack packager dependency cache intact' do
      before { buildpack_packager_execute(buildpack_fixture, tmpdir) }

      it 'outputs the dependencies downloaded, their versions, and cache location' do
        expect(subject).to include("Using go version 1.6.3 from local cache at: #{tmpdir}/.buildpack-packager/cache/https___buildpacks.cloudfoundry.org_concourse-binaries_go_go1.6.3.linux-amd64.tar.gz with size")
        expect(subject).to include("go version 1.6.3 matches the manifest provided sha256 checksum of 5ac238cd321a66a35c646d61e4cafd922929af0800c78b00375312c76e702e11")

        expect(subject).to include("Using godep version v74 from local cache at: #{tmpdir}/.buildpack-packager/cache/https___pivotal-buildpacks.s3.amazonaws.com_concourse-binaries_godep_godep-v74-linux-x64.tgz with size")
        expect(subject).to include("godep version v74 matches the manifest provided sha256 checksum of 6e6761b71e1518bf7716b3f383f10598afe5ce4592e6eea0184f17b85fd93813")
      end
    end

    context 'with auth credentials in the dependency uri' do
      let(:fixture_name) { 'buildpack-with-uri-credentials' }

      it 'outputs the dependencies download source url without the credentials' do
        expect(subject).to include('Downloading go version 1.6.3 from: https://-redacted-:-redacted-@buildpacks.cloudfoundry.org/concourse-binaries/go/go1.6.3.linux-amd64.tar.gz')
        expect(subject).to include('Downloading godep version v74 from: https://-redacted-:-redacted-@buildpacks.cloudfoundry.org/concourse-binaries/godep/godep-v74-linux-x64.tgz')
      end
    end
  end
end
