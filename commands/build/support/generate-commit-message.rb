#!/usr/bin/env ruby

def word_wrap(text)
  text.gsub(/(.{1,60})(\s|$)/, "\\1\n  ")
end

def collect_issues
  out = `git log $(git describe --tags --abbrev=0)...HEAD -E --grep '#[0-9]+' 2>/dev/null`
  issues = out.scan(/((?:\S+\/\S+)?#\d+)/).flatten
end

message = ENV["_message"]
if message.nil? || message.strip.empty?
  message = "Tag release v#{ENV["_version"]}"

  issues = collect_issues
  if issues.size > 0
    message += "\n\nReferences:\n  " + word_wrap(issues.uniq.sort.join(", "))
  end
end

puts message
