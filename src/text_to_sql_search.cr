require "yaml"
require "./text_to_sql_search/**"

module TextToSqlSearch
	class Config
		@operators_allowed = ["<", ">", "=", ":"]
		@negation_words    = ["!", "no", "not"]
		@ignored_words     = ["with", "than"]
		
		def initialize; end
		
		YAML.mapping(
			operators_allowed:   {type: Array(String)},
			negation_words:      {type: Array(String)},
			ignored_words:       {type: Array(String)},
		)
	end

	class Base
		# Instantiates new, default config. Returns existing config on subsequent calls.
		def config
			@config||= Config.new
		end
		
		# Given list and current position, peeks into upcoming elements to determine their type.
		# All decision-making is done based on current config.
		def peek_next( list, i, ignored= config.ignored_words)
			while el= list[i+=1]?
				next if ignored.includes? el
				return :operator if config.operators_allowed.includes? el
				return :negation if config.negation_words.includes? el
				return :todo
			end
		end

	end
end
