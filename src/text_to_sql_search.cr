require "yaml"
require "./text_to_sql_search/**"

module TextToSqlSearch
	class Config
		@operators_allowed = ["<", ">", "=", ":"]
		@negation_words    = ["!", "no", "not"]
		@ignored_words     = ["with", "than"]
		@split_regex       = /"(.*?)"|\s+|([()><:=+!-])/
		@strip             = true
		@default_joiner    = "AND"
		@default_negative  = false
		@first_element     = "1"
		
		def initialize; end
		
		YAML.mapping(
			operators_allowed: {type: Array(String)},
			negation_words:    {type: Array(String)},
			ignored_words:     {type: Array(String)},
			split_regex:       {type: Regex},
			strip:             {type: Bool},
			default_joiner:    {type: String},
			default_negative:  {type: Bool},
			first_element:     {type: String},
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

	def parse( input)
		# These happen one time to prepare the input line for parsing
		input= input.strip if config.strip
		tokens= input.split( config.split_regex).
		tokens.reject! {|t| t.blank? }
		
		# These initialize one-time and accumulate values as parsing advances
		terms= config.first_element # Accumulated SQL WHERE terms
		values= [] of String        # Their corresponding values (replacements for "?"s)
		count= tokens.size          # Total number of tokens we have for parsing
		i= 0                        # Current position in tokens array
		
		# These are re-set to these same defaults after each key=value is fully processed and a new one begins
		joiner= config.default_joiner      # Default joiner to put in SQL between (key=value) pairs
		negative= config.default_negative  # Are we in positive match or negative by default?
		content_before= ""                 # Small accumulator for pass-thru characters like opening parentheses

		while i< count
			token= tokens[i].strip if config.strip

			if config.ignored_words.includes? token
				i+= 1
				next
			end

		end
	end
	end
end
