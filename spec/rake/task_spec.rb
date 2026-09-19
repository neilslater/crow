# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rake'

describe Rake::Task do
  def check_documentation(source)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'lib'))
      File.write(File.join(dir, 'lib/crow.rb'), source)
      File.write(File.join(dir, 'example.gemspec'),
                 "Gem::Specification.new { |spec| spec.name = 'example'; spec.version = '0.0.0' }")
      Open3.capture3('bundle', 'exec', 'rake', '-f', File.expand_path('../../Rakefile', __dir__),
                     'documentation', chdir: dir)
    end
  end

  it 'accepts documented public source' do
    stdout, stderr, status = check_documentation("# A documented module.\nmodule Example; end\n")

    expect([status.success?, stdout + stderr]).to match [true, a_string_including('100.00% documented')]
  end

  it 'rejects an undocumented public method' do
    source = "# A documented module.\nmodule Example\n  def missing; end\nend\n"
    stdout, stderr, status = check_documentation(source)

    expect([status.success?, stdout + stderr])
      .to match [false, a_string_including('Example#missing', 'Public API documentation is incomplete')]
  end

  it 'rejects YARD warnings even when every object is documented' do
    source = "# A documented module.\n# @unknown_tag invalid\nmodule Example; end\n"
    stdout, stderr, status = check_documentation(source)

    expect([status.success?, stdout + stderr])
      .to match [false, a_string_including('Unknown tag', '100.00% documented')]
  end
end
