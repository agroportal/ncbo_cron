require 'logger'
require_relative 'ontology_submission_parser'

module NcboCron
  module Models

    class VowlGenerator

      GENERATED = 'VOWL'.freeze
      FAILED = 'ERROR_VOWL'.freeze
      attr_reader :processed, :failed, :skipped, :not_convertible

      def initialize(logger = nil, max_per_run: nil)
        @logger = logger || Logger.new($stdout)
        @max_per_run = max_per_run.to_i
        @processed = []
        @failed = []
        @skipped = 0
        @not_convertible = []
      end

      def run(acronyms: nil, force: false, redo_generated: false)
        candidates = latest_submissions(acronyms)
        pending = candidates.select { |sub| pending?(sub, force, redo_generated) }
        @skipped = candidates.length - pending.length

        targets = @max_per_run.positive? ? pending.first(@max_per_run) : pending
        remaining = pending.length - targets.length

        @logger.info("VOWL generation: #{targets.length} submission(s) to process, " \
                     "#{@skipped} up to date, previously failed or without a parsed file, " \
                     "#{remaining} deferred to the next run")
        @logger.flush

        targets.each { |sub| convert(sub) }

        @logger.info("VOWL generation done. Succeeded: #{@processed.length} (#{@processed.join(', ')}). " \
                     "Failed: #{@failed.length} (#{@failed.join(', ')}).")
        @logger.flush
        self
      end

      def pending(acronyms: nil, force: false, redo_generated: false)
        latest_submissions(acronyms).select { |sub| pending?(sub, force, redo_generated) }
      end

      def status_codes(submission)
        Array(submission.submissionStatus).map { |s| s.id.to_s.split('/').last }
      end

      private

      def pending?(submission, force, redo_generated)
        return false if submission.hasOntologyLanguage&.umls?

        unless submission.rdf_path && File.exist?(submission.rdf_path)
          @not_convertible << submission.ontology.acronym
          return false
        end

        codes = status_codes(submission)
        return redo_generated if codes.include?(GENERATED)
        return true if force || redo_generated

        !codes.include?(FAILED)
      end

      def latest_submissions(acronyms)
        includes = LinkedData::Models::OntologySubmission.goo_attrs_to_load
        includes << :submissionStatus unless includes.include?(:submissionStatus)
        includes << :hasOntologyLanguage unless includes.include?(:hasOntologyLanguage)

        wanted = acronyms && acronyms.map(&:strip).reject(&:empty?)
        latest = {}

        LinkedData::Models::OntologySubmission
          .where(submissionStatus: [code: 'RDF'])
          .include(includes)
          .to_a
          .each do |sub|
            acronym = sub.ontology.acronym
            next if wanted && !wanted.include?(acronym)

            latest[acronym] = sub if latest[acronym].nil? || sub.submissionId > latest[acronym].submissionId
          end

        latest.values
      end

      def convert(submission)
        acronym = submission.ontology.acronym
        @logger.info("Generating VOWL visualisation of #{submission.id}")
        @logger.flush

        OntologySubmissionParser.new.process_submission(
          @logger, submission.id.to_s,
          { process_rdf: false, diff: false, index_search: false, index_commit: false,
            run_metrics: false, reasoning: false, generate_foops: false, generate_vowl: true }
        )

        submission.bring(:submissionStatus)
        if status_codes(submission).include?(GENERATED)
          @processed << acronym
        else
          @failed << acronym
          @logger.error("#{acronym}: finished without #{GENERATED} (statuses: #{status_codes(submission)})")
        end
      rescue StandardError => e
        @failed << acronym
        @logger.error("#{acronym}: #{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
        @logger.flush
      end

    end
  end
end
