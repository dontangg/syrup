require "spec_helper"

describe Syrup do
  it "lists all institutions" do
    institution_list = Syrup.list_institutions
    
    institution_list.size.should == 1
    
    institution_list.should include("Zions Bank")
  end
  
  it "creates a Zions Bank institution" do
    Syrup.get_institution(:zions_bank).class.should == Syrup::Institutions::ZionsBank
  end
end