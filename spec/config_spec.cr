require "./spec_helper"

describe TextToSqlSearch do
  it "can create config" do
		t= TextToSqlSearch::Base.new
		c = t.config
		c.class.should eq TextToSqlSearch::Config
		c.infix_operator.class.should eq Regex
  end
end
