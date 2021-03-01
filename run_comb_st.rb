require 'octokit'
require 'json'
require 'optparse'

options = OpenStruct.new
options.branch = 'master'
options.verbosity = 0
options.com_tag = 0
options.com_back = 0

OptionParser.new do |opt|
  opt.on("-b", "--branch <BRANCH, ex. 1.10>") { |b| options.branch = b }
  opt.on("-t", "--tag <COMMIT TAG long format> (disables --commits_back option)") { |t| options.com_tag = t }
  opt.on("--commits_back <number of commits like for BRANCH~2, ex. 2>") { |c| options.com_back = c }
  opt.on("-v", "--verbosity <NUMBER, [0-3]>") { |v| options.verbosity = v.to_i }
end.parse!

if options.com_tag != 0
  git_sha = options.com_tag
else
  # remove EOL by strip
  git_sha = %x( git rev-parse origin/#{options.branch}~#{options.com_back} ).strip
end
if options.verbosity > 0
  puts "Options: #{options}"
  puts "In branch #{options.branch} search for GIT SHA: #{git_sha}"
end

client = Octokit::Client.new :access_token => ENV['GITHUB_PATOKEN']

# returns the same as client.last_response.data
client.repository_workflow_runs('tarantool/tarantool', {event: 'push', branch: options.branch})

# point and start work from the initial response
last_response = client.last_response

# print found results pages
if options.verbosity > 1
  number_of_pages = last_response.rels[:last].href.match(/page=(\d+).*$/)[1]
  puts "There are #{last_response.data.total_count} results, on #{number_of_pages} pages!"
end

# print in loop all paginated pages
loop do
  # for verbosity print all the current page data
  if options.verbosity > 2
    puts last_response.data.map(&:to_s).to_json
  end

  # print from workflow array needed item
  workflow_array = last_response.data[:workflow_runs]
  workflow_array.each do |item|
    if item[:head_sha] == git_sha
      puts "#{item[:conclusion]} #{item[:name]}"
    end
  end

  if last_response.rels[:next].nil?
    break
  end

  # iterate and get next page data
  last_response = last_response.rels[:next].get
end

