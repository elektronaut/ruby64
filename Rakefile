# frozen_string_literal: true

require "rubygems"
require "rake/testtask"

FIXTURE_DIR = "test/fixtures/65x02"
FIXTURE_SUBPATH = "6502/v1"
FIXTURE_PATH = "#{FIXTURE_DIR}/#{FIXTURE_SUBPATH}".freeze
FIXTURE_REPO = "https://github.com/SingleStepTests/65x02"

# Check out the 6502 single step test fixtures with a single shallow, blobless
# partial clone and a sparse checkout scoped to just those files. Git only
# transfers the (compressed) blobs we ask for, so this is far cheaper than
# fetching each file over HTTP. The tests read straight out of the checkout.
def checkout_fixtures
  require "fileutils"

  sh("git", "clone", "--quiet", "--depth", "1", "--filter=blob:none",
     "--no-checkout", FIXTURE_REPO, FIXTURE_DIR)
  Dir.chdir(FIXTURE_DIR) do
    sh("git", "sparse-checkout", "set", FIXTURE_SUBPATH)
    sh("git", "checkout", "--quiet")
  end
rescue StandardError
  FileUtils.rm_rf(FIXTURE_DIR)
  raise
end

task default: "test"

namespace :fixtures do
  desc "Check out the 65x02 single step test fixtures unless already present"
  task :download do
    if Dir.exist?(FIXTURE_PATH)
      puts "65x02 fixtures already present."
    else
      puts "Checking out 65x02 fixtures into #{FIXTURE_DIR} from #{FIXTURE_REPO}"
      checkout_fixtures
    end
  end
end

Rake::TestTask.new do |task|
  task.pattern = "test/test_*.rb"
end

Rake::Task["test"].enhance(["fixtures:download"])
