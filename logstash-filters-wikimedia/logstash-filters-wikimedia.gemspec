Gem::Specification.new do |s|

  s.name            = 'logstash-filters-wikimedia'
  s.version         = '0.5.5'
  s.licenses        = ['Apache-2.0']
  s.summary         = "Backports of logstash plugins for wikimedia installation. Includes the prune and de_dot filters"
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install /path/to/gemfile. This gem is not a stand-alone program"
  s.authors         = ["Elastic"]
  s.email           = 'info@elastic.co'
  s.homepage        = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", '>= 1.60', '<= 2.99'

  s.add_development_dependency 'logstash-devutils'
end

