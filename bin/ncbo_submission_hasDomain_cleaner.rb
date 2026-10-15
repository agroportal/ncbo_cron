#!/usr/bin/env ruby

require 'bundler/setup'
require 'rdf'
require 'sparql/client'
require_relative '../lib/ncbo_cron'
config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
abort("Please create a config/config.rb file using the config/config.rb.sample as a template") unless config_exists
require_relative '../config/config'

graph_uri = RDF::URI("http://data.bioontology.org/metadata/OntologySubmission")
predicates = [
  RDF::URI("http://omv.ontoware.org/2005/05/ontology#hasDomain"),
  RDF::URI("http://omv.ontoware.org/2005/05/ontology#keywords")
]

sparql = Goo.sparql_query_client

predicates.each do |predicate|
  puts "\nChecking predicate: #{predicate}"

  query = <<SPARQL
SELECT DISTINCT ?s ?o
FROM <#{graph_uri}>
WHERE {
  ?s <#{predicate}> ?o .
  FILTER(
    datatype(?o) = <http://www.w3.org/2000/01/rdf-schema#Literal> ||
    lang(?o) != ""
  )
}
SPARQL

  results = sparql.query(query)

  results.each do |solution|
    subject = solution[:s]
    bad_literal = solution[:o]
    fixed_literal = RDF::Literal.new(bad_literal.value)  # plain literal

    next if bad_literal == fixed_literal  # already clean

    # Prepare delete and insert graphs
    g_del = RDF::Graph.new << [subject, predicate, bad_literal]
    g_add = RDF::Graph.new << [subject, predicate, fixed_literal]

    Goo.sparql_update_client.delete_data(g_del, graph: graph_uri)
    Goo.sparql_update_client.insert_data(g_add, graph: graph_uri)

    puts "✔ Fixed #{predicate}: #{subject} – '#{bad_literal}' => '#{fixed_literal}'"
  end
end