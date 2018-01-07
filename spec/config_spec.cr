require "./spec_helper"

describe TextToSqlSearch do
  it "can create config" do
		t= TextToSqlSearch::Base.new
		c = t.config
		c.class.should eq TextToSqlSearch::Config
		c.operators_allowed.should eq ["<", ">", "=", ":"]
  end
end
