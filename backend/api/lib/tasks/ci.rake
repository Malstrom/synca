# frozen_string_literal: true

PROTECTED_BRANCHES = %w[main master].freeze

desc "Run all CI checks: RuboCop autocorrect, bundle audit, tests + auto-commit + push"
task ci: :environment do
  branch = `git rev-parse --abbrev-ref HEAD`.strip

  # Auto-create a feature branch if on a protected branch
  if PROTECTED_BRANCHES.include?(branch)
    new_branch = "dev/ci-#{Time.now.strftime("%Y%m%d-%H%M%S")}"
    puts "⚠️  You are on '#{branch}'. Creating branch '#{new_branch}'..."
    system("git checkout -b #{new_branch}") || exit(1)
    branch = new_branch
  end

  steps = [
    { name: "RuboCop autocorrect", cmd: "bundle exec rubocop -a --format progress" },
    { name: "Gem CVE audit",       cmd: "bundle exec bundle-audit update && bundle exec bundle-audit check" },
    { name: "Tests + Coverage",    cmd: "bin/rails test" }
  ]

  failed = []

  steps.each do |step|
    puts "\n#{"=" * 50}"
    puts "▶  #{step[:name]}"
    puts "=" * 50
    system(step[:cmd]) || failed << step[:name]
  end

  puts "\n#{"=" * 50}"

  if failed.any?
    puts "❌  Failed: #{failed.join(", ")}"
    exit(1)
  end

  dirty = `git diff --name-only`.strip
  if dirty.present?
    puts "\n▶  Auto-committing RuboCop fixes..."
    system("git add .") || exit(1)
    system('git commit -m "style: rubocop autocorrections"') || exit(1)
  end

  puts "\n▶  Pushing to origin/#{branch}..."
  system("git push origin #{branch}") || exit(1)
  puts "\n✅  All checks passed and pushed to origin/#{branch}!"
  puts "    Open a PR at: https://github.com/Malstrom/synca/compare/#{branch}"
end
