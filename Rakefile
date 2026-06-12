# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

VENDORED_REPOS = {
  "65x02" => {
    repo: "https://github.com/SingleStepTests/65x02",
    sparse: "6502/v1"
  },
  "VICE-testprogs" => {
    repo: "https://github.com/libsidplayfp/VICE-testprogs"
  }
}.freeze

# Check out a vendored test repository with a single shallow, blobless
# partial clone, optionally restricted to a sparse subpath. Git only
# transfers the (compressed) blobs we ask for, so this is far cheaper than
# fetching each file over HTTP. The tests read straight out of the checkout.
def checkout_vendored(dir, repo:, sparse: nil)
  require "fileutils"

  args = ["git", "clone", "--quiet", "--depth", "1", "--filter=blob:none"]
  args << "--no-checkout" if sparse
  sh(*args, repo, dir)
  return unless sparse

  Dir.chdir(dir) do
    sh("git", "sparse-checkout", "set", sparse)
    sh("git", "checkout", "--quiet")
  end
rescue StandardError
  FileUtils.rm_rf(dir)
  raise
end

task default: "test"

namespace :vendor do
  VENDORED_REPOS.each do |name, config|
    desc "Check out #{name} into vendor/#{name} unless already present"
    task name do
      dir = File.join("vendor", name)
      if Dir.exist?(File.join(dir, config[:sparse].to_s))
        puts "#{name} already present."
      else
        puts "Checking out #{name} into #{dir} from #{config[:repo]}"
        checkout_vendored(dir, **config)
      end
    end
  end

  desc "Check out all vendored test repositories"
  task checkout: VENDORED_REPOS.keys
end

Rake::TestTask.new do |task|
  task.pattern = "test/test_*.rb"
end

Rake::Task["test"].enhance(["vendor:65x02"])
