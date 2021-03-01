require 'octokit'
require 'json'

client = Octokit::Client.new :access_token => ENV['GITHUB_PATOKEN']

#results = client.repository_workflow_runs('tarantool/tarantool', options: {status: 'completed', event: 'push', branch: 'master'})
# nosqlbench
#results = client.workflow_runs('tarantool/tarantool', 5857085, options: {status: 'completed', event: 'push', branch: 'master'})
# debian_11
results = client.workflow_runs('tarantool/tarantool', 4543487, options: {status: 'completed', event: 'push', branch: 'master'})

# point and start work from the initial response
last_response = client.last_response

puts "================================"
puts "Last page link: #{last_response.rels[:last].href}"

puts "================================"
number_of_pages = last_response.rels[:last].href.match(/page=(\d+).*$/)[1]
puts "There are #{results.total_count} results, on #{number_of_pages} pages!"

puts "Print every page:"

# print initial page data
puts last_response.data.map(&:to_s).to_json

# print in loop other pages
until last_response.rels[:next].nil?
    # print number of the next page
    next_page = last_response.rels[:next].href.match(/page=(\d+).*$/)[1]
    puts "================================"
    puts
    puts "Next page #{next_page}: #{last_response.rels[:next].href}"
    puts "================================"

    # iterate and get next page data
    last_response = last_response.rels[:next].get

    # print newly get next page data
    puts last_response.data.map(&:to_s).to_json
end

